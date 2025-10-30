import 'package:flutter/material.dart';
import 'package:foodiebox/screens/admin/admin_home_page.dart';

// ===================== Data Model =====================
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final Color color; // Card background color

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
  });
}

// ===================== Mock Data =====================
final List<SubscriptionPlan> mockPlans = [
  SubscriptionPlan(
    id: 'p1',
    name: "Premium",
    description: "Full access, priority support, unlimited usage.",
    color: Colors.indigo.shade100,
  ),
  SubscriptionPlan(
    id: 'p2',
    name: "Standard",
    description: "Basic access, email support, monthly limit.",
    color: Colors.green.shade100,
  ),
  SubscriptionPlan(
    id: 'p3',
    name: "Basic",
    description: "Limited access, no support, daily limit.",
    color: Colors.orange.shade100,
  ),
];

// ===================== Main Entry =====================
class SubscriptionApp extends StatelessWidget {
  const SubscriptionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Subscriptions Management',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          color: Colors.white,
          elevation: 0.5,
          iconTheme: IconThemeData(color: Color(0xFF1F2937)),
          titleTextStyle: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        useMaterial3: true,
      ),
      home: const SubscriptionsManagementScreen(),
    );
  }
}

// ===================== Subscription Screen =====================
class SubscriptionsManagementScreen extends StatelessWidget {
  const SubscriptionsManagementScreen({super.key});

  void _handlePlanTap(BuildContext context, SubscriptionPlan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriptionPlanDetailScreen(plan: plan),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminHomePage()),
            );
          },
        ),
        title: const Text('Subscriptions Management'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Plans',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 16),
            ...mockPlans.map(
              (plan) => PlanCard(
                plan: plan,
                onTap: () => _handlePlanTap(context, plan),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== Custom Plan Card =====================
class PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final VoidCallback onTap;

  const PlanCard({
    super.key,
    required this.plan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: plan.color,
        borderRadius: BorderRadius.circular(12.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.05),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Image Placeholder
                Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 28,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plan.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                // Right arrow
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(
                    Icons.chevron_right,
                    size: 24,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== Subscription Plan Detail Screen =====================
class SubscriptionPlanDetailScreen extends StatelessWidget {
  final SubscriptionPlan plan;

  const SubscriptionPlanDetailScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(plan.name),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              plan.description,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Features:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '- Example feature 1\n- Example feature 2\n- Example feature 3',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== Run App =====================
void main() {
  runApp(const SubscriptionApp());
}
