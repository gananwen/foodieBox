import 'package:flutter/material.dart';

const Color kAppBackgroundColor = Color.fromARGB(255, 255, 255, 238);
const Color kCardColor = Color(0xFFFFFFFF);
const Color kTextColor = Color(0xFF000000);
const Color kPrimaryActionColor = Color.fromARGB(255, 120, 41, 51);
const Color kSecondaryAccentColor = Color.fromARGB(255, 235, 255, 210);
const Color kCategoryColor = Color(0xFFE8FFC9);

// 🔸 New Yellow Gradient Colors
const Color kYellowLight = Color(0xFFFFF9C4); // light yellow
const Color kYellowMedium = Color(0xFFFFF176); // medium yellow
const Color kYellowSoft = Color(0xFFFFF59D); // soft yellow for buttons

// 💡 New Color: A deeper, gold-like yellow for better contrast in the header
const Color kYellowGold = Color(0xFFFFE082); // A more saturated yellow

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

const LinearGradient kYellowHeaderGradient = LinearGradient(
  colors: [kYellowMedium, kYellowSoft],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// 👇 THE NEW GRADIENT FOR THE PROFILE HEADER
const LinearGradient kProfileHeaderGradient = LinearGradient(
  colors: [kYellowMedium, kYellowGold], // Use Medium and the new Gold color
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
);
