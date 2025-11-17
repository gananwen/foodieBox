import 'package:flutter/material.dart';
import '../../util/styles.dart'; 
import 'onboarding_role_selection_page.dart';

// --- Onboarding Page Template (for Pages 1, 2, and 3) ---
class OnboardingPageTemplate extends StatelessWidget {
  final String title;
  final String description;
  final Widget image; 
  final VoidCallback? onNext;
  final VoidCallback? onSkip;
  final VoidCallback? onBack;
  final bool isLastCarouselPage; 
  final int currentPage;

  const OnboardingPageTemplate({
    super.key,
    required this.title,
    required this.description,
    required this.image,
    required this.currentPage, 
    this.onNext,
    this.onSkip,
    this.onBack,
    this.isLastCarouselPage = false,
  });

  @override
  Widget build(BuildContext context) {
    final showBackButton = currentPage > 0;
    
    // Determine the button text based on if this is the final carousel slide
    final String buttonText = isLastCarouselPage ? 'GET STARTED' : 'NEXT';

    return Container( 
      // Set to kCardColor (White) for clean contrast with images
      color: kCardColor, 
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Skip Button
          Align(
            alignment: Alignment.topRight,
            child: TextButton(
              onPressed: onSkip,
              child: const Text('Skip', style: TextStyle(color: Colors.grey)),
            ),
          ),
          const Spacer(flex: 1),

          // Image 
          SizedBox(
            height: 250,
            // The images will now look seamless against the white background.
            child: image,
          ),
          const Spacer(flex: 1),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 15),

          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const Spacer(flex: 2),

          // Navigation Buttons (Back & Next/Get Started)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showBackButton)
                TextButton(
                  onPressed: onBack,
                  child: const Text('Back', style: TextStyle(color: Colors.grey)),
                )
              else 
                const SizedBox(width: 60), 

              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kYellowLight,
                  minimumSize: const Size(120, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                child: Text(
                  buttonText, 
                  // **FIXED CONTRAST:** Use kTextColor (Black) on light background
                  style: const TextStyle(color: kTextColor, fontSize: 16, fontWeight: FontWeight.bold), 
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// --- Main Onboarding Screen ---
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final int _numPages = 4; 

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _goToNextPage() {
    if (_currentPage < _numPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } 
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  void _skipOnboarding() {
    _pageController.animateToPage(
      _numPages - 1, 
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    ); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set the Scaffold background to kCardColor (White)
      backgroundColor: kCardColor, 
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              // Page 1: Discover Deals
              OnboardingPageTemplate(
                title: 'Discover Smart Food Deals',
                description: 'Find delicious discounted groceries, fresh surplus food, and fun blindboxes—all near you. Start saving money and the planet today!',
                image: Image.asset('assets/images/onboarding_discover_deals.png'),
                currentPage: _currentPage,
                onBack: _goToPreviousPage,
                onNext: _goToNextPage,
                onSkip: _skipOnboarding,
                isLastCarouselPage: false,
              ),

              // Page 2: Zero Waste Impact
              OnboardingPageTemplate(
                title: 'Fight Food Waste with Every Order',
                description: 'We partner with local vendors to rescue perfect, near-expiry items. Every purchase reduces waste and supports a sustainable food chain.',
                image: Image.asset('assets/images/onboarding_zero_waste.png'),
                currentPage: _currentPage,
                onBack: _goToPreviousPage,
                onNext: _goToNextPage,
                onSkip: _skipOnboarding,
                isLastCarouselPage: false,
              ),

              // Page 3: Fast & Secure Delivery
              OnboardingPageTemplate(
                title: 'Fast & Secure Delivery',
                description: 'Enjoy hassle-free, secure payment options and track your order in real-time. Your discounted goods will arrive fresh and fast at your door.',
                image: Image.asset('assets/images/onboarding_delivery.png'),
                currentPage: _currentPage,
                onBack: _goToPreviousPage,
                onNext: _goToNextPage,
                onSkip: _skipOnboarding,
                isLastCarouselPage: true, // Button text is "GET STARTED"
              ),

              // Page 4: Role Selection 
              const OnboardingRoleSelectionPage(), 
            ],
          ),

          // --- Bottom Indicator Dots ---
          Positioned(
            bottom: 20, 
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_numPages, (index) => _buildDot(index, _currentPage)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, int currentPage) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: 8.0,
      decoration: BoxDecoration(
        color: currentPage == index ? kYellowMedium : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }
}