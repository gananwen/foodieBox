import 'package:flutter/material.dart';

/// --- Color Constants ---
const Color kAppBackgroundColor = Color(0xFFFEFFE1); // Background
const Color kCardColor = Color(0xFFFFFFFF); // Card/Container background
const Color kTextColor = Color(0xFF000000); // Primary text color
const Color kPrimaryActionColor =
    Color(0xFFFFA3AF); // Buttons / Highlight actions
const Color kSecondaryAccentColor =
    Color(0xFFE8FFC9); // Secondary sections / accents
const Color kCategoryColor = Color(0xFFE8FFC9); // Categories / highlights
const Color kSecondaryAccentLight = Color(0xFFFFFFB2); // Light yellow accent

/// --- Text Styles ---
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
