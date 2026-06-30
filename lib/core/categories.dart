// Default category seed data, taken from the PRD expense heads and income
// types. Seeded into the `categories` table on first launch; user-editable
// later via Settings.

class SeedCategory {
  final String id;
  final String name;
  final String kind; // 'income' | 'expense'
  final String icon; // material icon name (resolved in UI)
  final int sortOrder;
  const SeedCategory(this.id, this.name, this.kind, this.icon, this.sortOrder);
}

const List<SeedCategory> kSeedCategories = [
  // Income types
  SeedCategory('inc_catering', 'Catering', 'income', 'restaurant', 0),
  SeedCategory('inc_cloud', 'Cloud Kitchen', 'income', 'storefront', 1),
  SeedCategory('inc_other', 'Other Income', 'income', 'payments', 2),

  // Expense heads (PRD 9.3)
  SeedCategory('exp_salaries', 'Salaries', 'expense', 'badge', 0),
  SeedCategory('exp_advances', 'Advances', 'expense', 'account_balance_wallet', 1),
  SeedCategory('exp_groceries', 'Groceries', 'expense', 'shopping_basket', 2),
  SeedCategory('exp_transport', 'Transport', 'expense', 'local_shipping', 3),
  SeedCategory('exp_oil', 'Oil', 'expense', 'water_drop', 4),
  SeedCategory('exp_veggies', 'Veggies', 'expense', 'eco', 5),
  SeedCategory('exp_dairy', 'Dairy', 'expense', 'icecream', 6),
  SeedCategory('exp_packaging', 'Packaging', 'expense', 'inventory_2', 7),
  SeedCategory('exp_gas', 'Gas/Cylinder', 'expense', 'propane_tank', 8),
  SeedCategory('exp_rent', 'Rent', 'expense', 'home', 9),
  SeedCategory('exp_electricity', 'Electricity', 'expense', 'bolt', 10),
  SeedCategory('exp_repairs', 'Repairs', 'expense', 'build', 11),
  SeedCategory('exp_marketing', 'Marketing/Ads', 'expense', 'campaign', 12),
  SeedCategory('exp_misc', 'Miscellaneous', 'expense', 'more_horiz', 13),
];

/// Payment modes (PRD 9.2 / 9.3).
const List<String> kPaymentModes = ['Cash', 'UPI', 'Paytm', 'Bank', 'Other'];

/// Business tags (PRD 12.1).
const List<String> kTags = ['Catering', 'Cloud Kitchen', 'Event', 'Other'];
