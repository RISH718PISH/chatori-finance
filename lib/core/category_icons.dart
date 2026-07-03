import 'package:flutter/material.dart';

/// Maps the icon names stored on category rows to const [IconData]. A const map
/// is required because Flutter tree-shakes icons, so they can't be looked up by
/// string at runtime.
const Map<String, IconData> kCategoryIcons = {
  // Income
  'restaurant': Icons.restaurant,
  'storefront': Icons.storefront,
  'savings': Icons.savings,
  'payments': Icons.payments,
  // Payroll
  'badge': Icons.badge,
  'account_balance_wallet': Icons.account_balance_wallet,
  // Food staples
  'shopping_basket': Icons.shopping_basket,
  'eco': Icons.eco,
  'icecream': Icons.icecream,
  'kebab_dining': Icons.kebab_dining,
  'grass': Icons.grass,
  'grain': Icons.grain,
  'water_drop': Icons.water_drop,
  'park': Icons.park,
  // Beverages
  'local_bar': Icons.local_bar,
  'local_drink': Icons.local_drink,
  // Bakery
  'cake': Icons.cake,
  // Fuel & packaging
  'propane_tank': Icons.propane_tank,
  'inventory_2': Icons.inventory_2,
  'dinner_dining': Icons.dinner_dining,
  // Event-specific
  'group': Icons.group,
  'event_seat': Icons.event_seat,
  'local_florist': Icons.local_florist,
  'airport_shuttle': Icons.airport_shuttle,
  // Overhead
  'local_shipping': Icons.local_shipping,
  'home': Icons.home,
  'bolt': Icons.bolt,
  'build': Icons.build,
  'campaign': Icons.campaign,
  'more_horiz': Icons.more_horiz,
};

IconData categoryIcon(String? name) =>
    kCategoryIcons[name] ?? Icons.category_outlined;
