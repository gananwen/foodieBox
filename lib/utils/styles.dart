import 'package:flutter/material.dart';

// Color codes: FEFFE1, FFFFB2, E8FFC9, FFA3AF, 000000

// 1. Primary Base (Lightest Yellow/Off-White)
const Color kAppBackgroundColor = Color(0xFFFEFFE1);  // FEFFE1 - Main background
const Color kCardColor = Colors.white;                // White - For input fields and content cards

// 2. Highlighting & Action (Pink)
const Color kPrimaryActionColor = Color(0xFFFFA3AF);  // FFA3AF - Reserved for Promotions, Deals, Buttons

// 3. Category/Grouping Color (Light Green)
const Color kCategoryColor = Color(0xFFE8FFC9);        // E8FFC9 - Used for category chips, illustration box

// 4. Accent Color (Yellow)
const Color kSecondaryAccentColor = Color(0x0fffffb2); // FFFFB2 - Used for subtle accents like the Logo box/Placeholders

// 5. Text Color
const Color kTextColor = Color(0xFF000000);           // Black

// --- 2. Centralized Text Styles ---
const TextStyle kHeading1Style = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: kTextColor,
);

const TextStyle kButtonTextStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: Colors.white,
);

const TextStyle kLinkTextStyle = TextStyle(
  color: kPrimaryActionColor,
  fontWeight: FontWeight.bold,
);

const TextStyle kLabelTextStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.bold,
  color: kTextColor,
);