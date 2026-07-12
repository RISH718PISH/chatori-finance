// Default category seed data, taken from the PRD expense heads and income
// types. Seeded into the `categories` table on first launch; user-editable
// later via Settings.

/// Which section of the monthly P&L a category belongs to.
enum PlSection { revenue, cogs, operating }

class SeedCategory {
  final String id;
  final String name;
  final String kind; // 'income' | 'expense'
  final String icon; // material icon name (resolved in UI)
  final int sortOrder;
  final PlSection plSection;
  const SeedCategory(
    this.id,
    this.name,
    this.kind,
    this.icon,
    this.sortOrder,
    this.plSection,
  );
}

const List<SeedCategory> kSeedCategories = [
  // ── Income types ─────────────────────────────────────────────────
  SeedCategory('inc_catering', 'Catering', 'income', 'restaurant', 0,
      PlSection.revenue),
  SeedCategory('inc_cloud', 'Cloud Kitchen', 'income', 'storefront', 1,
      PlSection.revenue),
  SeedCategory('inc_advance', 'Customer Advance', 'income', 'savings', 2,
      PlSection.revenue),
  SeedCategory('inc_other', 'Other Income', 'income', 'payments', 3,
      PlSection.revenue),

  // ── Expense heads ────────────────────────────────────────────────
  // Ordered for the picker grid: payroll → food staples → beverages →
  // bakery → fuel/packaging → event-specific → general overhead.
  // plSection controls where each line sits in the monthly P&L
  // (COGS = direct food/event inputs; Operating = indirect/overhead).

  // Payroll (Operating)
  SeedCategory(
      'exp_salaries', 'Salaries', 'expense', 'badge', 0, PlSection.operating),
  SeedCategory('exp_advances', 'Advances', 'expense', 'account_balance_wallet',
      1, PlSection.operating),

  // Food staples (COGS)
  SeedCategory('exp_groceries', 'Groceries', 'expense', 'shopping_basket', 2,
      PlSection.cogs),
  SeedCategory('exp_veggies', 'Veggies', 'expense', 'eco', 3, PlSection.cogs),
  SeedCategory('exp_dairy', 'Dairy', 'expense', 'icecream', 4, PlSection.cogs),
  SeedCategory('exp_meat', 'Meat & Poultry', 'expense', 'kebab_dining', 5,
      PlSection.cogs),
  SeedCategory('exp_spices', 'Spices & Masalas', 'expense', 'grass', 6,
      PlSection.cogs),
  SeedCategory(
      'exp_grains', 'Grains & Flour', 'expense', 'grain', 7, PlSection.cogs),
  SeedCategory('exp_oil', 'Oil', 'expense', 'water_drop', 8, PlSection.cogs),
  SeedCategory(
      'exp_fruits', 'Fruits', 'expense', 'park', 9, PlSection.cogs),

  // Beverages (COGS)
  SeedCategory('exp_beverages', 'Beverages', 'expense', 'local_bar', 10,
      PlSection.cogs),
  SeedCategory('exp_water', 'Water Bottles', 'expense', 'local_drink', 11,
      PlSection.cogs),

  // Bakery (COGS)
  SeedCategory('exp_bakery', 'Bakery & Sweets', 'expense', 'cake', 12,
      PlSection.cogs),

  // Fuel & packaging (COGS)
  SeedCategory(
      'exp_gas', 'Gas/Cylinder', 'expense', 'propane_tank', 13, PlSection.cogs),
  SeedCategory('exp_packaging', 'Packaging', 'expense', 'inventory_2', 14,
      PlSection.cogs),
  SeedCategory('exp_disposables', 'Disposables & Cutlery', 'expense',
      'dinner_dining', 15, PlSection.cogs),

  // Event-specific (COGS — direct event costs)
  SeedCategory('exp_event_labor', 'Event Labor', 'expense', 'group', 16,
      PlSection.cogs),
  SeedCategory('exp_event_rentals', 'Event Rentals', 'expense', 'event_seat',
      17, PlSection.cogs),
  SeedCategory('exp_decor', 'Décor & Flowers', 'expense', 'local_florist', 18,
      PlSection.cogs),
  SeedCategory('exp_event_transport', 'Event Transportation', 'expense',
      'airport_shuttle', 19, PlSection.cogs),

  // General overhead (Operating)
  SeedCategory('exp_transport', 'Transport', 'expense', 'local_shipping', 20,
      PlSection.operating),
  SeedCategory('exp_rent', 'Rent', 'expense', 'home', 21, PlSection.operating),
  SeedCategory('exp_electricity', 'Electricity', 'expense', 'bolt', 22,
      PlSection.operating),
  SeedCategory(
      'exp_repairs', 'Repairs', 'expense', 'build', 23, PlSection.operating),
  SeedCategory('exp_marketing', 'Marketing/Ads', 'expense', 'campaign', 24,
      PlSection.operating),
  SeedCategory('exp_misc', 'Miscellaneous', 'expense', 'more_horiz', 25,
      PlSection.operating),
];

/// P&L section for a category name; unknown expense categories default to
/// operating, unknown income to revenue.
PlSection plSectionFor(String categoryName, {required bool isIncome}) {
  for (final c in kSeedCategories) {
    if (c.name == categoryName) return c.plSection;
  }
  return isIncome ? PlSection.revenue : PlSection.operating;
}

/// Payment modes (PRD 9.2 / 9.3). "Cash+UPI" is a split: the transaction's
/// amount is divided between cash_paise and upi_paise columns; the two must
/// sum to amount_paise. Reports treat the row as one entry but split its
/// value between Cash and Digital buckets.
const kPaymentModeSplit = 'Cash+UPI';
const List<String> kPaymentModes = [
  'Cash',
  'UPI',
  kPaymentModeSplit,
  'Bank',
  'Other',
];

/// Business tags (PRD 12.1).
const List<String> kTags = ['Catering', 'Cloud Kitchen', 'Event', 'Other'];
