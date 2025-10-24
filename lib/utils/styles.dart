import 'package:flutter/material.dart';

const Color kAppBackgroundColor = Color.fromARGB(255, 255, 255, 238);
const Color kCardColor = Color(0xFFFFFFFF);
const Color kTextColor = Color(0xFF000000);
const Color kPrimaryActionColor = Color.fromARGB(255, 120, 41, 51);
const Color kSecondaryAccentColor = Color.fromARGB(255, 235, 255, 210);
const Color kCategoryColor = Color(0xFFE8FFC9);

const TextStyle kLabelTextStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: kTextColor,
);

const TextStyle kLinkTextStyle = TextStyle(
  color: kPrimaryActionColor,
  fontWeight: FontWeight.bold,
);

/// --- Gradient Constants ---
const LinearGradient kPromotionGradient = LinearGradient(
  colors: [Color(0xFFFFA3AF), Color(0xFFF48FB1)], // soft pink to deeper pink
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
