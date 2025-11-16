import 'package:flutter/material.dart';

const Color kAppBackgroundColor = Color.fromARGB(255, 255, 255, 238);
const Color kCardColor = Color(0xFFFFFFFF);
const Color kTextColor = Color(0xFF000000);
const Color kPrimaryActionColor = Color.fromARGB(255, 120, 41, 51); 
const Color kSecondaryAccentColor = Color.fromARGB(255, 235, 255, 210);
const Color kCategoryColor = Color(0xFFE8FFC9);
const Color kOnboardingBackgroundColor = Color(0xFFFBF9F4); 

const Color kYellowLight = Color(0xFFFFF9C4); 
const Color kYellowMedium = Color(0xFFFFF176); 
const Color kYellowSoft = Color(0xFFFFF59D); 


const Color kYellowGold = Color(0xFFFFE082); 

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
// Soft pink to deeper pink for promotions
const LinearGradient kPromotionGradient = LinearGradient(
  colors: [Color(0xFFFFA3AF), Color(0xFFF48FB1)], 
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kYellowHeaderGradient = LinearGradient(
  colors: [kYellowMedium, kYellowSoft],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Gradient for the profile header
const LinearGradient kProfileHeaderGradient = LinearGradient(
  colors: [kYellowMedium, kYellowGold], 
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
);

const TextStyle kHintTextStyle = TextStyle(
  fontSize: 13,
  color: Colors.black54,
  fontWeight: FontWeight.w400,
);