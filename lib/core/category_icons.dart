import 'package:flutter/material.dart';

/// Maps the icon names stored on category rows to const [IconData]. A const map
/// is required because Flutter tree-shakes icons, so they can't be looked up by
/// string at runtime.
const Map<String, IconData> kCategoryIcons = {
  'restaurant': Icons.restaurant,
  'storefront': Icons.storefront,
  'savings': Icons.savings,
  'payments': Icons.payments,
  'badge': Icons.badge,
  'account_balance_wallet': Icons.account_balance_wallet,
  'shopping_basket': Icons.shopping_basket,
  'local_shipping': Icons.local_shipping,
  'water_drop': Icons.water_drop,
  'eco': Icons.eco,
  'icecream': Icons.icecream,
  'inventory_2': Icons.inventory_2,
  'propane_tank': Icons.propane_tank,
  'home': Icons.home,
  'bolt': Icons.bolt,
  'build': Icons.build,
  'campaign': Icons.campaign,
  'more_horiz': Icons.more_horiz,
};

IconData categoryIcon(String? name) =>
    kCategoryIcons[name] ?? Icons.category_outlined;
