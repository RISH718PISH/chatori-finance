// Chatori Finance — invoice parsing via Gemini vision.
//
// WHY THIS EXISTS
// The on-device ML Kit path flattened `RecognizedText` to a plain string,
// discarding the bounding-box geometry that makes an invoice a *table*.
// Rebuilding a 10-column table from newline-delimited prose is not
// reliably solvable, and in practice it captured address blocks, GST
// sub-column values and footer legal text as "line items".
//
// This function takes the image instead and asks a vision model for the
// structured rows directly. It also exists so the API key lives in
// Supabase's secret store and never ships inside the APK.
//
// PROVIDER: Gemini, because a Google AI Studio key is free and needs no
// payment method. The JSON this function RETURNS is provider-agnostic and
// must stay byte-identical — lib/features/screenshot/ai_parsed_invoice.dart
// parses it, so changing the response shape breaks the app.
//
// Deploy:  supabase functions deploy parse-invoice --project-ref <ref>
// Secret:  supabase secrets set GEMINI_API_KEY=...   (free key from
//          https://aistudio.google.com/apikey)

const MODEL = "gemini-2.5-flash";
const GEMINI_URL =
  `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`;

// Must stay in sync with kSeedCategories in lib/core/categories.dart.
// Passed to the model so suggested_category is always a value the app
// already understands — no fuzzy mapping needed on the client.
const EXPENSE_CATEGORIES = [
  "Groceries",
  "Veggies",
  "Dairy",
  "Meat & Poultry",
  "Spices & Masalas",
  "Grains & Flour",
  "Oil",
  "Fruits",
  "Beverages",
  "Water Bottles",
  "Bakery & Sweets",
  "Gas/Cylinder",
  "Packaging",
  "Disposables & Cutlery",
  "Event Labor",
  "Event Rentals",
  "Décor & Flowers",
  "Event Transportation",
  "Transport",
  "Rent",
  "Electricity",
  "Repairs",
  "Marketing/Ads",
  "Miscellaneous",
];

// The unit vocabulary Quantity.unitFromSymbol (lib/core/quantity.dart) can
// actually store. "packet" is deliberately absent: a packet is a PACK SIZE,
// not a unit of measure. Allowing it produces items whose stock reads
// "3 packets" while consumption wants grams, with no way to reconcile the
// two — so pack lines must be converted to a base unit here or dropped.
const UNITS = ["kg", "g", "l", "ml", "pcs", "dozen"];

const SYSTEM_PROMPT =
  `You extract line items from Indian supplier invoices for a catering and cloud-kitchen business.

Return ONLY genuine purchased products.

Do NOT return as line items any of the following, which commonly appear on these invoices:
- Vendor or buyer address blocks, GSTIN numbers, PIN codes, phone numbers, email addresses
- Column headers ("Description", "HSN", "Qty", "Rate", "Amount", "Taxable")
- Tax breakdown columns (values like "49.2+49.2+0" are CGST+SGST+cess, not products)
- HSN/SAC codes standing alone (e.g. "1008")
- Subtotal, tax, round-off, grand total or amount-payable rows
- Page markers ("Page 1 of 1"), signature lines, "Authorised Signatory"
- Legal declarations ("We declare that this invoice shows the actual price...")
- Bank details, terms and conditions
- CIN / PAN numbers

Rules:
- amount is the line total for that product in RUPEES as a decimal number (e.g. 1543.83), NOT paise. Never include currency symbols or thousands separators.
- Delivery, convenience or service fees ARE real charges: include them with category "Miscellaneous".
- If a product name wraps across multiple visual lines, join it into one description.
- unit must be exactly one of: ${UNITS.join(", ")}. Use null if you genuinely cannot determine it.
- The invoice's own UoM column often uses words that are NOT units of measure. Convert them:
  * "Count", "Per piece", "Each", "Nos", "No", "Unit" -> "pcs"
  * "Kg"/"Kgs" -> "kg", "Gm"/"Gms" -> "g", "Ltr"/"Litre" -> "l"
  * "Pack" / "Packet" / "Box" / "Bag" is a PACK SIZE, not a unit. Read the pack
    size out of the description and convert to a base unit. Examples:
      "Amul - Butter Salted, 500 gm", Qty 2, UoM Pack  -> qty 1,   unit "kg"
      "Napkin 1 Ply, 100 Pulls (Pack of 20)", Qty 1, UoM Pack -> qty 2000, unit "pcs"
      "Bagasse Bowl (Pack of 250)", Qty 2, UoM Pack    -> qty 500, unit "pcs"
    If the description contains no pack size you can multiply out, set BOTH qty
    and unit to null. Never report a pack count as "pcs" — that silently
    corrupts stock tracking.
- qty is the numeric quantity expressed in the unit you returned, AFTER any pack conversion above.
- unit_price is per that same unit, in rupees. Set it to null rather than guessing; amount is what matters.
- suggested_category must be exactly one of the allowed category strings.
- confidence: 1.0 when the row is crisp and unambiguous; below 0.7 when you had to guess any field. Be honest — low confidence flags the row for human review, which is far better than a silent error.
- If the image is unreadable or is not an invoice, return an empty items array and set total to null.

Accuracy matters more than completeness: it is better to mark a row low-confidence than to invent a value.

Return JSON only, matching the required schema.`;

// Gemini's responseSchema is a SUBSET of OpenAPI 3.0 and rejects the union
// types the Anthropic tool schema used (`type: ["string","null"]`).
// Nullability is expressed as `nullable: true` instead.
//
// `unit` deliberately carries NO enum: pairing enum with nullable is
// inconsistently supported, and a schema rejection would fail the whole
// request. The allowed values are in the prompt and re-validated below.
const RESPONSE_SCHEMA = {
  type: "object",
  properties: {
    vendor_name: {
      type: "string",
      nullable: true,
      description: "Supplier/seller business name, e.g. 'Hyperpure'.",
    },
    invoice_number: { type: "string", nullable: true },
    invoice_date: {
      type: "string",
      nullable: true,
      description: "Invoice date as YYYY-MM-DD.",
    },
    subtotal: {
      type: "number",
      nullable: true,
      description: "Taxable value before tax, in rupees.",
    },
    tax: {
      type: "number",
      nullable: true,
      description: "Total tax (CGST+SGST+IGST+cess), in rupees.",
    },
    total: {
      type: "number",
      nullable: true,
      description: "Final payable amount in rupees.",
    },
    items: {
      type: "array",
      items: {
        type: "object",
        properties: {
          description: { type: "string" },
          hsn: { type: "string", nullable: true },
          qty: { type: "number", nullable: true },
          unit: {
            type: "string",
            nullable: true,
            description: `One of: ${UNITS.join(", ")}. Null if unknown.`,
          },
          unit_price: {
            type: "number",
            nullable: true,
            description: "Price per unit in rupees.",
          },
          amount: { type: "number", description: "Line total in rupees." },
          suggested_category: { type: "string", enum: EXPENSE_CATEGORIES },
          confidence: { type: "number" },
        },
        required: [
          "description",
          "amount",
          "suggested_category",
          "confidence",
        ],
        propertyOrdering: [
          "description",
          "hsn",
          "qty",
          "unit",
          "unit_price",
          "amount",
          "suggested_category",
          "confidence",
        ],
      },
    },
  },
  required: ["items"],
  propertyOrdering: [
    "vendor_name",
    "invoice_number",
    "invoice_date",
    "subtotal",
    "tax",
    "total",
    "items",
  ],
};

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

/** Rupee decimal -> integer paise. Rounds half-up; null-safe. */
function toPaise(v: unknown): number | null {
  if (v === null || v === undefined) return null;
  const n = typeof v === "string" ? Number(v) : (v as number);
  if (!Number.isFinite(n)) return null;
  return Math.round(n * 100);
}

/**
 * Coerce whatever the model returned into a unit the app can store, or null.
 * Mirrors Quantity.unitFromSymbol in lib/core/quantity.dart. Returning null
 * is a valid, safe answer: the expense still books, only stock is skipped.
 */
function normaliseUnit(v: unknown): string | null {
  if (typeof v !== "string") return null;
  const s = v.trim().toLowerCase().replace(/\./g, "").replace(/^per\s+/, "");
  const map: Record<string, string> = {
    kg: "kg", kgs: "kg", kilogram: "kg", kilograms: "kg",
    g: "g", gm: "g", gms: "g", gram: "g", grams: "g",
    l: "l", ltr: "l", ltrs: "l", litre: "l", litres: "l", liter: "l",
    ml: "ml", mls: "ml", millilitre: "ml", milliliter: "ml",
    pcs: "pcs", pc: "pcs", piece: "pcs", pieces: "pcs", nos: "pcs",
    no: "pcs", unit: "pcs", units: "pcs", count: "pcs", each: "pcs",
    ea: "pcs",
    dozen: "dozen", dz: "dozen", doz: "dozen",
  };
  return map[s] ?? null;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "POST only" }, 405);

  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) {
    return json({
      error:
        "GEMINI_API_KEY is not set. Get a free key at https://aistudio.google.com/apikey and add it under Edge Functions -> Secrets (exact name, no spaces).",
    }, 500);
  }

  // Require a caller token. Supabase verifies the JWT before invoking, but
  // fail loudly rather than silently serving unauthenticated traffic.
  if (!req.headers.get("Authorization")) {
    return json({ error: "Missing Authorization header" }, 401);
  }

  let imageBase64: string;
  let mediaType: string;
  try {
    const body = await req.json();
    imageBase64 = body.image_base64;
    mediaType = body.media_type ?? "image/jpeg";
    if (!imageBase64 || typeof imageBase64 !== "string") {
      return json({ error: "image_base64 is required" }, 400);
    }
  } catch (_) {
    return json({ error: "Invalid JSON body" }, 400);
  }

  let aiRes: Response;
  try {
    aiRes = await fetch(GEMINI_URL, {
      method: "POST",
      headers: {
        "x-goog-api-key": apiKey,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: SYSTEM_PROMPT }] },
        contents: [{
          role: "user",
          parts: [
            { inline_data: { mime_type: mediaType, data: imageBase64 } },
            {
              text:
                "Extract every genuine purchased product from this invoice.",
            },
          ],
        }],
        generationConfig: {
          temperature: 0,
          responseMimeType: "application/json",
          responseSchema: RESPONSE_SCHEMA,
          maxOutputTokens: 8192,
        },
      }),
    });
  } catch (e) {
    return json({ error: `Could not reach Gemini: ${e}` }, 502);
  }

  if (!aiRes.ok) {
    const detail = await aiRes.text();
    // Surface the status so the client can distinguish an invalid key (400
    // API_KEY_INVALID) or an exhausted free tier (429 RESOURCE_EXHAUSTED)
    // from a genuine bug.
    return json(
      { error: "Gemini API error", status: aiRes.status, detail },
      502,
    );
  }

  const payload = await aiRes.json();
  const candidate = payload.candidates?.[0];
  const text = candidate?.content?.parts
    ?.map((p: { text?: string }) => p.text ?? "")
    .join("") ?? "";

  if (!text.trim()) {
    // MAX_TOKENS on a very long invoice, or SAFETY. Say which.
    return json({
      error: "Gemini returned no structured result",
      status: 502,
      detail: `finishReason=${candidate?.finishReason ?? "unknown"}`,
    }, 502);
  }

  let raw: Record<string, unknown>;
  try {
    raw = JSON.parse(text);
  } catch (_) {
    return json({
      error: "Gemini returned malformed JSON",
      detail: text.slice(0, 500),
    }, 502);
  }

  const rawItems = Array.isArray(raw.items) ? raw.items : [];

  const items = rawItems.map((it: Record<string, unknown>) => {
    const unit = normaliseUnit(it.unit);
    const qty = (it.qty as number | null) ?? null;
    return {
      description: String(it.description ?? "").trim(),
      hsn: (it.hsn as string | null) ?? null,
      // Quantity and unit travel together: a quantity without a storable
      // unit cannot post to stock, and keeping the number around invites a
      // caller to assume a unit that was never read.
      qty: unit === null ? null : qty,
      unit: qty === null ? null : unit,
      unit_price_paise: toPaise(it.unit_price),
      amount_paise: toPaise(it.amount) ?? 0,
      suggested_category: (it.suggested_category as string) ?? "Groceries",
      confidence: typeof it.confidence === "number" ? it.confidence : 0.5,
    };
  }).filter((it) => it.description.length > 0 && it.amount_paise > 0);

  const totalPaise = toPaise(raw.total);
  const itemsSum = items.reduce((s, it) => s + it.amount_paise, 0);

  return json({
    vendor_name: (raw.vendor_name as string | null) ?? null,
    invoice_number: (raw.invoice_number as string | null) ?? null,
    invoice_date: (raw.invoice_date as string | null) ?? null,
    subtotal_paise: toPaise(raw.subtotal),
    tax_paise: toPaise(raw.tax),
    total_paise: totalPaise,
    items,
    // Reconciliation is computed here so the client cannot forget to.
    // total_unknown is deliberately distinct from a zero difference: the
    // old client conflated them and so could never warn in exactly the
    // case where parsing had failed worst.
    reconciliation: {
      items_sum_paise: itemsSum,
      total_unknown: totalPaise === null,
      difference_paise: totalPaise === null ? null : totalPaise - itemsSum,
      balanced: totalPaise !== null && totalPaise === itemsSum,
    },
    model: MODEL,
    usage: payload.usageMetadata ?? null,
  });
});
