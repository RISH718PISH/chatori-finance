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
  // Income types
  SeedCategory('inc_catering', 'Catering', 'income', 'restaurant', 0,
      PlSection.revenue),
  SeedCategory('inc_cloud', 'Cloud Kitchen', 'income', 'storefront', 1,
      PlSection.revenue),
  SeedCategory('inc_advance', 'Customer Advance', 'income', 'savings', 2,
      PlSection.revenue),
  SeedCategory('inc_other', 'Other Income', 'income', 'payments', 3,
      PlSection.revenue),

  // Expense heads (PRD 9.3), in display order. plSection marks whether each is
  // a direct food/packaging input (COGS) or an operating expense.
  SeedCategory(
      'exp_salaries', 'Salaries', 'expense', 'badge', 0, PlSection.operating),
  SeedCategory('exp_advances', 'Advances', 'expense', 'account_balance_wallet',
      1, PlSection.operating),
  SeedCategory('exp_groceries', 'Groceries', 'expense', 'shopping_basket', 2,
      PlSection.cogs),
  SeedCategory('exp_transport', 'Transport', 'expense', 'local_shipping', 3,
      PlSection.operating),
  SeedCategory('exp_oil', 'Oil', 'expense', 'water_drop', 4, PlSection.cogs),
  SeedCategory('exp_veggies', 'Veggies', 'expense', 'eco', 5, PlSection.cogs),
  SeedCategory('exp_dairy', 'Dairy', 'expense', 'icecream', 6, PlSection.cogs),
  SeedCategory('exp_packaging', 'Packaging', 'expense', 'inventory_2', 7,
      PlSection.cogs),
  SeedCategory(
      'exp_gas', 'Gas/Cylinder', 'expense', 'propane_tank', 8, PlSection.cogs),
  SeedCategory('exp_rent', 'Rent', 'expense', 'home', 9, PlSection.operating),
  SeedCategory('exp_electricity', 'Electricity', 'expense', 'bolt', 10,
      PlSection.operating),
  SeedCategory(
      'exp_repairs', 'Repairs', 'expense', 'build', 11, PlSection.operating),
  SeedCategory('exp_marketing', 'Marketing/Ads', 'expense', 'campaign', 12,
      PlSection.operating),
  SeedCategory('exp_misc', 'Miscellaneous', 'expense', 'more_horiz', 13,
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

/// Payment modes (PRD 9.2 / 9.3).
const List<String> kPaymentModes = ['Cash', 'UPI', 'Paytm', 'Bank', 'Other'];

/// Business tags (PRD 12.1).
const List<String> kTags = ['Catering', 'Cloud Kitchen', 'Event', 'Other'];
