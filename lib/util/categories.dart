// 这个 Map 存储了所有 Grocery 类别和它们对应的子类别
const Map<String, List<String>> kGroceryCategories = {
  'Frozen': [
    'Frozen Meat',
    'Ice Cream & Desserts',
    'Frozen Seafood',
    'Ready-to-Eat'
  ],
  'Baked Goods': ['Bread', 'Cakes', 'Pastries', 'Donuts'],
  'Vegetables': ['Leafy Greens', 'Root Vegetables', 'Fruits', 'Herbs'],
  'Spices': ['Dry Spices', 'Seasoning Mixes', 'Sauces & Pastes'],
  'Beverage': [
    'Juices',
    'Soft Drinks',
    'Coffee & Tea',
    'Dairy & Plant-Based Milk'
  ],
  'Non-Halal Food': ['Pork', 'Alcoholic Beverages', 'Non-Halal Snacks'],
};
