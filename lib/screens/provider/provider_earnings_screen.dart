import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../core/theme.dart';
import '../../services/provider/provider_service.dart';
import '../../widgets/provider/provider_navigation_bar.dart';
import '../../widgets/provider/earnings_card.dart';
import '../../widgets/provider/quick_stats_card.dart';

class ProviderEarningsScreen extends StatefulWidget {
  const ProviderEarningsScreen({super.key});

  @override
  State<ProviderEarningsScreen> createState() => _ProviderEarningsScreenState();
}

class _ProviderEarningsScreenState extends State<ProviderEarningsScreen>
    with TickerProviderStateMixin {
  final ProviderService _providerService = ProviderService();
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late TabController _tabController;

  bool _isLoading = true;
  int _selectedIndex = 4; // Earnings tab
  String _selectedPeriod = 'This Week';
  
  // Earnings data
  Map<String, dynamic> _earningsData = {};
  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> _earningsBreakdown = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _tabController = TabController(length: 4, vsync: this);
    _loadEarningsData();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEarningsData() async {
    try {
      // Simulate loading earnings data
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (mounted) {
        setState(() {
          _earningsData = _generateEarningsData();
          _recentTransactions = _generateTransactions();
          _earningsBreakdown = _generateBreakdown();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _generateEarningsData() {
    return {
      'totalEarnings': 3250.0,
      'weeklyEarnings': 850.0,
      'monthlyEarnings': 3250.0,
      'yearlyEarnings': 42500.0,
      'pendingPayouts': 425.0,
      'completedServices': 28,
      'averageRating': 4.8,
      'totalHours': 45.5,
      'weeklyGrowth': '+12%',
      'monthlyGrowth': '+8%',
      'chartData': [650.0, 720.0, 580.0, 850.0, 790.0, 920.0, 850.0],
      'chartLabels': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    };
  }

  List<Map<String, dynamic>> _generateTransactions() {
    return [
      {
        'id': '1',
        'patientName': 'Emily Johnson',
        'serviceType': 'General Consultation',
        'amount': 85.0,
        'date': DateTime.now().subtract(const Duration(hours: 2)),
        'status': 'completed',
        'paymentMethod': 'Credit Card',
      },
      {
        'id': '2',
        'patientName': 'Michael Chen',
        'serviceType': 'Home Visit',
        'amount': 120.0,
        'date': DateTime.now().subtract(const Duration(hours: 5)),
        'status': 'pending',
        'paymentMethod': 'Insurance',
      },
      {
        'id': '3',
        'patientName': 'Sarah Williams',
        'serviceType': 'Emergency Care',
        'amount': 200.0,
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'status': 'completed',
        'paymentMethod': 'Cash',
      },
      {
        'id': '4',
        'patientName': 'David Brown',
        'serviceType': 'Follow-up Visit',
        'amount': 65.0,
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'status': 'completed',
        'paymentMethod': 'Digital Wallet',
      },
      {
        'id': '5',
        'patientName': 'Lisa Anderson',
        'serviceType': 'Vaccination',
        'amount': 45.0,
        'date': DateTime.now().subtract(const Duration(days: 3)),
        'status': 'completed',
        'paymentMethod': 'Credit Card',
      },
    ];
  }

  List<Map<String, dynamic>> _generateBreakdown() {
    return [
      {
        'category': 'General Consultations',
        'amount': 1250.0,
        'color': AppTheme.primaryColor,
        'percentage': 38.5,
      },
      {
        'category': 'Home Visits',
        'amount': 980.0,
        'color': const Color(0xFF10B981),
        'percentage': 30.2,
      },
      {
        'category': 'Emergency Services',
        'amount': 650.0,
        'color': const Color(0xFFEF4444),
        'percentage': 20.0,
      },
      {
        'category': 'Follow-up Visits',
        'amount': 370.0,
        'color': const Color(0xFFF59E0B),
        'percentage': 11.3,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _slideController,
          builder: (context, child) {
            return SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  _buildPeriodSelector(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildTransactionsTab(),
                        _buildAnalyticsTab(),
                        _buildPayoutsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: ProviderNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          HapticFeedback.lightImpact();
          _handleNavigation(index);
        },
        hasNotification: _earningsData['pendingPayouts'] > 0,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20), // Added extra top padding
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet,
            color: AppTheme.primaryColor,
            size: 28,
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Earnings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  'Track your income and performance',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  color: const Color(0xFF10B981),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '+12%',
                  style: TextStyle(
                    color: const Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['Today', 'This Week', 'This Month', 'This Year'];
    
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: periods.length,
        itemBuilder: (context, index) {
          final period = periods[index];
          final isSelected = period == _selectedPeriod;
          
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
                HapticFeedback.lightImpact();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? AppTheme.primaryColor 
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  period,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: AppTheme.primaryColor,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Transactions'),
          Tab(text: 'Analytics'),
          Tab(text: 'Payouts'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main earnings cards
          Row(
            children: [
              Expanded(
                child: EarningsCard(
                  title: 'Total Earnings',
                  amount: '\$${_earningsData['totalEarnings'].toStringAsFixed(0)}',
                  period: _selectedPeriod,
                  icon: Icons.account_balance_wallet,
                  color: AppTheme.primaryColor,
                  percentageChange: _earningsData['weeklyGrowth'],
                  isPositiveChange: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: EarningsCard(
                  title: 'Pending Payouts',
                  amount: '\$${_earningsData['pendingPayouts'].toStringAsFixed(0)}',
                  period: 'Ready for withdrawal',
                  icon: Icons.schedule,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Performance stats
          StatsGrid(
            cards: [
              QuickStatsCard(
                title: 'Services',
                value: '${_earningsData['completedServices']}',
                subtitle: 'Completed',
                icon: Icons.medical_services,
                color: const Color(0xFF10B981),
              ),
              QuickStatsCard(
                title: 'Rating',
                value: '${_earningsData['averageRating']}',
                subtitle: 'Average',
                icon: Icons.star,
                color: const Color(0xFFF59E0B),
              ),
              QuickStatsCard(
                title: 'Hours',
                value: '${_earningsData['totalHours']}',
                subtitle: 'This week',
                icon: Icons.schedule,
                color: AppTheme.primaryColor,
              ),
              QuickStatsCard(
                title: 'Growth',
                value: '${_earningsData['weeklyGrowth']}',
                subtitle: 'vs last week',
                icon: Icons.trending_up,
                color: const Color(0xFF10B981),
                badge: const StatsBadge(
                  text: 'NEW',
                  color: Color(0xFF10B981),
                  isNew: true,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Earnings chart
          EarningsChart(
            data: List<double>.from(_earningsData['chartData']),
            labels: List<String>.from(_earningsData['chartLabels']),
          ),
          
          const SizedBox(height: 20),
          
          // Earnings breakdown
          EarningsBreakdown(
            breakdownData: _earningsBreakdown,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          ..._recentTransactions.map((transaction) {
            return _buildTransactionCard(transaction);
          }),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final isCompleted = transaction['status'] == 'completed';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.schedule,
                  color: isCompleted 
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction['patientName'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      transaction['serviceType'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${transaction['amount'].toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isCompleted 
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                  Text(
                    _formatDate(transaction['date']),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isCompleted ? 'Completed' : 'Pending',
                  style: TextStyle(
                    color: isCompleted 
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                transaction['paymentMethod'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Analytics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          PerformanceCard(
            title: 'Patient Rating',
            rating: _earningsData['averageRating'],
            totalReviews: 127,
            trend: '+0.3',
            isPositiveTrend: true,
          ),
          
          const SizedBox(height: 20),
          
          EarningsChart(
            data: List<double>.from(_earningsData['chartData']),
            labels: List<String>.from(_earningsData['chartLabels']),
          ),
          
          const SizedBox(height: 20),
          
          EarningsBreakdown(
            breakdownData: _earningsBreakdown,
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  const Color(0xFF10B981),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available for Withdrawal',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${_earningsData['pendingPayouts'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _showWithdrawalDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Withdraw Funds',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Payout History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          // Mock payout history
          ...List.generate(5, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadows,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bank Transfer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        Text(
                          'Processed on ${_formatDate(DateTime.now().subtract(Duration(days: index * 7)))}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Text(
                    '\$${(450 - index * 50).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showWithdrawalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available amount: \$${_earningsData['pendingPayouts'].toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Withdrawal Amount',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Bank Account',
                hintText: 'Select account ending in 1234',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Withdrawal request submitted successfully!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.pop(context); // Back to dashboard
        break;
      case 1:
        // Navigate to appointments
        break;
      case 2:
        // Navigate to navigation
        break;
      case 3:
        // Navigate to messages
        break;
      case 4:
        // Already in earnings
        break;
    }
  }
}
