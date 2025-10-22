import 'package:flutter/material.dart';
import 'constants.dart';

// --- Color Mappings ---

// FEFFE1: Lightest Yellow/Cream for background
const Color kAppBackgroundColor = AppColors.primaryBackgroundLightest;

// E8FFC9: Light Green/Mint for section backgrounds and primary buttons (like Sign In)
const Color kCategoryColor = AppColors.sectionBackground;

// FFFFFB2: Light Yellow Accent, good for secondary containers or highlights
const Color kCardColor = AppColors.secondaryAccentLight;

// FFA3AF: Action/Highlight (Pink/Rose), reserved for promotions and important elements
const Color kPrimaryActionColor = AppColors.actionHighlight;

// Black
const Color kTextColor = AppColors.textBoundary;

// --- Text Styles ---
const TextStyle kLinkTextStyle = TextStyle(
  color: kTextColor,
  fontWeight: FontWeight.bold,
  decoration: TextDecoration.underline,
);
