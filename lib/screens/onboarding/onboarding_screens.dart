import 'package:flutter/material.dart';
import 'package:firstv/routes/app_routes.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  late AnimationController _imageController;
  late AnimationController _textController;
  late AnimationController _buttonController;
  
  late Animation<double> _imageFadeAnimation;
  late Animation<double> _imageScaleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _buttonFadeAnimation;

  final List<Map<String, String>> onboardingData = [
    {
      'title': 'Quick. Simple. Trusted ',
      'subtitle':'healthcare from anywhere. ',
      'image': 'assets/images/Frame3.svg',
    },
    {
      'title': 'we bring care ',
      'subtitle':'  to your doorstep',
      'image': 'assets/images/Frame2.svg',
    },
    {
      'title': 'Start your health journey now',
      'subtitle': 'Start now and take care of your health',
      'image': 'assets/images/Frame1.svg',
    },
  ];

  @override
  void initState() {
    super.initState();
    
    _imageController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _imageFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _imageController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
    ));

    _imageScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _imageController,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));

    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
    ));

    _textSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _buttonFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
    ));

    // Start initial animations
    _startAnimations();
  }

  void _startAnimations() async {
    if (!mounted) return;
    if (_imageController.isAnimating || _textController.isAnimating || _buttonController.isAnimating) return;
    
    try {
      await _imageController.forward();
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      await _textController.forward();
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      _buttonController.forward();
    } catch (e) {
      // Animation was disposed, ignore
    }
  }

  void _resetAnimations() {
    if (!mounted) return;
    try {
      _imageController.reset();
      _textController.reset();
      _buttonController.reset();
      _startAnimations();
    } catch (e) {
      // Controllers were disposed, ignore
    }
  }

  @override
  void dispose() {
    _imageController.dispose();
    _textController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView.builder(
        controller: _pageController,
        itemCount: onboardingData.length,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
          // Reset animations when page changes
          _resetAnimations();
        },
        itemBuilder: (context, index) {
          return buildPage(
            image: onboardingData[index]['image']!,
            title: onboardingData[index]['title']!,
            subtitle: onboardingData[index]['subtitle']!,
          );
        },
      ),
      bottomSheet: _currentPage == 2
          ? buildStartButton(context)
          : buildNextButton(),
    );
  }

  Widget buildPage({required String image, required String title, required String subtitle}) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
        child: Column(
          children: [
            // Top spacing
            const SizedBox(height: 40),
            
                         // SVG Image - positioned in upper part with animations
            Expanded(
              flex: 3,
              child: Center(
                child: AnimatedBuilder(
                  animation: _imageController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _imageScaleAnimation.value,
                      child: Opacity(
                        opacity: _imageFadeAnimation.value,
                        child: SvgPicture.asset(
                          image,
                          height: 280,
                          fit: BoxFit.contain,
                          placeholderBuilder: (context) => Container(
                            height: 80,
                            width: 80,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(),
                          ),
                          colorFilter: null,
                          semanticsLabel: 'Onboarding illustration',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
                         // Text content - positioned in lower part with animations
             Expanded(
               flex: 2,
               child: AnimatedBuilder(
                 animation: _textController,
                 builder: (context, child) {
                   return Transform.translate(
                     offset: Offset(0, _textSlideAnimation.value),
                     child: Opacity(
                       opacity: _textFadeAnimation.value,
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Text(
                             title,
                             textAlign: TextAlign.center,
                             style: const TextStyle(
                              fontStyle: FontStyle.italic,
                               fontSize: 28,
                               fontWeight: FontWeight.bold,
                               color: Color(0xFF1976D2),
                               height: 1.2,
                             ),
                           ),
                           const SizedBox(height: 16),
                           Text(
                             subtitle,
                             textAlign: TextAlign.center,
                             style: const TextStyle(
                               fontSize: 18,
                               color: Color(0xFF666666),
                               height: 1.4,
                             ),
                           ),
                         ],
                       ),
                     ),
                   );
                 },
               ),
             ),
            
            // Bottom spacing
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildNextButton() {
    return Container(
      height: 80,
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
             child: AnimatedBuilder(
         animation: _buttonController,
         builder: (context, child) {
           return Opacity(
             opacity: _buttonFadeAnimation.value,
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 // Page indicators
                 Row(
                   children: List.generate(
                     onboardingData.length,
                     (index) => AnimatedContainer(
                       duration: const Duration(milliseconds: 300),
                       margin: const EdgeInsets.only(right: 8),
                       width: _currentPage == index ? 24 : 8,
                       height: 8,
                       decoration: BoxDecoration(
                         color: _currentPage == index ? Colors.blue : Colors.grey.shade300,
                         borderRadius: BorderRadius.circular(4),
                       ),
                     ),
                   ),
                 ),
                 
                 // Next button
                 TextButton(
                   onPressed: () {
                     _pageController.nextPage(
                       duration: const Duration(milliseconds: 300),
                       curve: Curves.easeInOut,
                     );
                   },
                   child: const Text(
                     "NEXT",
                     style: TextStyle(
                       fontSize: 16,
                       fontWeight: FontWeight.w600,
                       color: Colors.blue,
                     ),
                   ),
                 ),
               ],
             ),
           );
         },
       ),
    );
  }

  Widget buildStartButton(BuildContext context) {
    return Container(
      height: 80,
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        },
        child: const Text(
          "Start Now",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
