// Chatori Finance — invoice parsing via Claude vision.
//
// WHY THIS EXISTS
// The on-device ML Kit path flattened `RecognizedText` to a plain string,
// discarding the bounding-box geometry that makes an invoice a *table*.
// Rebuilding a 10-column table from newline-delimited prose is not
// reliably solvable, and in practice it captured address blocks, GST
// sub-column values and footer legal text as "line items".
//
// This function takes the image instead and asks a vision model for the
// structured rows directly. It also exists so the Anthropic API key lives
// in Supabase's secret store and never ships inside the APK.
//
// Deploy:  supabase functions deploy parse-invoice
// Secret:  supabase secrets set ANTHROPIC_API_KEY=sk-ant-...

const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
const ANTHROPIC_VERSION = "2023-06-01";
const MODEL = "claude-sonnet-5";

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

const UNITS = ["kg", "g", "l", "ml", "pcs", "dozen", "packet"];

const SYSTEM_PROMPT =
  `You extract line items from Indian supplier invoices for a catering and cloud-kitchen business.

Return ONLY genuine purchased products via the record_invoice tool.

Do NOT return as line items any of the following, which commonly appear on these invoices:
- Vendor or buyer address blocks, GSTIN numbers, PIN codes, phone numbers, email addresses
- Column headers ("Description", "HSN", "Qty", "Rate", "Amount", "Taxable")
- Tax breakdown columns (values like "49.2+49.2+0" are CGST+SGST+cess, not products)
- HSN/SAC codes standing alone (e.g. "1008")
- Subtotal, tax, round-off, grand total or amount-payable rows
- Page markers ("Page 1 of 1"), signature lines, "Authorised Signatory"
- Legal declarations ("We declare that this invoice shows the actual price...")
- Bank details, terms and conditions

Rules:
- amount is the line total for that product in RUPEES as a decimal number (e.g. 1543.83), NOT paise. Never include currency symbols or thousands separators.
- Delivery, convenience or service fees ARE real charges: include them with category "Miscellaneous".
- If a product name wraps across multiple visual lines, join it into one description.
- unit must be one of ${UNITS.join(", ")} — pick the closest match. Use null if genuinely unclear.
- qty is the numeric quantity in that unit. Use null if unreadable.
- confidence: 1.0 when the row is crisp and unambiguous; below 0.7 when you had to guess any field. Be honest — low confidence flags the row for human review, which is far better than a silent error.
- If the image is unreadable or is not an invoice, return an empty items array and set total to null.

Accuracy matters more than completeness: it is better to mark a row low-confidence than to invent a value.`;

const TOOL = {
  name: "record_invoice",
  description: "Record the structured contents of a supplier invoice.",
  input_schema: {
    type: "object",
    properties: {
      vendor_name: {
        type: ["string", "null"],
        description: "Supplier/seller business name, e.g. 'Hyperpure'.",
      },
      invoice_number: { type: ["string", "null"] },
      invoice_date: {
        type: ["string", "null"],
        description: "Invoice date as YYYY-MM-DD.",
      },
      subtotal: {
        type: ["number", "null"],
        description: "Taxable value before tax, in rupees.",
      },
      tax: {
        type: ["number", "null"],
        description: "Total tax (CGST+SGST+IGST+cess), in rupees.",
      },
      total: {
        type: ["number", "null"],
        description: "Final payable amount in rupees.",
      },
      items: {
        type: "array",
        items: {
          type: "object",
          properties: {
            description: { type: "string" },
            hsn: { type: ["string", "null"] },
            qty: { type: ["number", "null"] },
            unit: { type: ["string", "null"], enum: [...UNITS, null] },
            unit_price: {
              type: ["number", "null"],
              description: "Price per unit in rupees.",
            },
            amount: {
              type: "number",
              description: "Line total in rupees.",
            },
            suggested_category: {
              type: "string",
              enum: EXPENSE_CATEGORIES,
            },
            confidence: { type: "number", minimum: 0, maximum: 1 },
          },
          required: ["description", "amount", "suggested_category", "confidence"],
        },
      },
    },
    required: ["items"],
  },
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

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "POST only" }, 405);

  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) {
    return json({
      error:
        "ANTHROPIC_API_KEY is not set. Add it under Edge Functions -> Secrets (exact name, no spaces).",
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
    aiRes = await fetch(ANTHROPIC_URL, {
      method: "POST",
      headers: {
        "x-api-key": apiKey,
        "anthropic-version": ANTHROPIC_VERSION,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: 4096,
        system: SYSTEM_PROMPT,
        tools: [TOOL],
        // Force the tool so we always get structured output, never prose.
        tool_choice: { type: "tool", name: "record_invoice" },
        messages: [{
          role: "user",
          content: [
            {
              type: "image",
              source: {
                type: "base64",
                media_type: mediaType,
                data: imageBase64,
              },
            },
            {
              type: "text",
              text:
                "Extract every genuine purchased product from this invoice.",
            },
          ],
        }],
      }),
    });
  } catch (e) {
    return json({ error: `Could not reach Anthropic: ${e}` }, 502);
  }

  if (!aiRes.ok) {
    const detail = await aiRes.text();
    // Surface the status so the client can distinguish "out of credit"
    // (402/429) from a genuine bug.
    return json({ error: "Anthropic API error", status: aiRes.status, detail },
      502);
  }

  const payload = await aiRes.json();
  const toolUse = (payload.content ?? []).find(
    (c: { type: string }) => c.type === "tool_use",
  );
  if (!toolUse) {
    return json({ error: "Model returned no structured result" }, 502);
  }

  const raw = toolUse.input as Record<string, unknown>;
  const rawItems = Array.isArray(raw.items) ? raw.items : [];

  const items = rawItems.map((it: Record<string, unknown>) => ({
    description: String(it.description ?? "").trim(),
    hsn: (it.hsn as string | null) ?? null,
    qty: (it.qty as number | null) ?? null,
    unit: (it.unit as string | null) ?? null,
    unit_price_paise: toPaise(it.unit_price),
    amount_paise: toPaise(it.amount) ?? 0,
    suggested_category: (it.suggested_category as string) ?? "Groceries",
    confidence: typeof it.confidence === "number" ? it.confidence : 0.5,
  })).filter((it) => it.description.length > 0 && it.amount_paise > 0);

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
    usage: payload.usage ?? null,
  });
});
