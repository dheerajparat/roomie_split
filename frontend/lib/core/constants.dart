import 'package:flutter/material.dart';

class AppConstants {
  static const String apiBaseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "http://localhost:8000/api",
  );

  static const List<Map<String, dynamic>> categories = [
    {
      "name": "Groceries",
      "icon": Icons.shopping_basket_rounded,
      "color": Colors.green,
    },
    {
      "name": "Vegetables",
      "icon": Icons.eco_rounded,
      "color": Colors.teal,
    },
    {
      "name": "Food & Dining",
      "icon": Icons.restaurant_rounded,
      "color": Colors.orange,
    },
    {
      "name": "Utilities",
      "icon": Icons.bolt_rounded,
      "color": Colors.amber,
    },
    {
      "name": "Rent",
      "icon": Icons.home_rounded,
      "color": Colors.indigo,
    },
    {
      "name": "Household",
      "icon": Icons.cleaning_services_rounded,
      "color": Colors.purple,
    },
    {
      "name": "Snacks",
      "icon": Icons.fastfood_rounded,
      "color": Colors.deepOrange,
    },
    {
      "name": "Other",
      "icon": Icons.category_rounded,
      "color": Colors.blueGrey,
    },
  ];

  static Map<String, dynamic> getCategory(String name) {
    return categories.firstWhere(
      (c) => c["name"].toString().toLowerCase() == name.toLowerCase(),
      orElse: () => {
        "name": name,
        "icon": Icons.category_rounded,
        "color": Colors.blueGrey,
      },
    );
  }
}
