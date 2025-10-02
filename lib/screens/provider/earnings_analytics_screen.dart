import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/provider_analytics_service.dart';

// App Theme Colors
class AppColors {
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color secondaryGreen = Color(0xFF43A047);
  static const Color red = Color(0xFFE53935);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color darkGrey = Color(0xFF757575);
}

class EarningsAnalyticsScreen extends StatefulWidget {
  const EarningsAnalyticsScreen({super.key});

  @override
  State<EarningsAnalyticsScreen> createState() => _EarningsAnalyticsScreenState();
}

class _EarningsAnalyticsScreenState extends State<EarningsAnalyticsScreen> {
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.weekly;
  List<EarningsData> _earningsData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEarningsData();
  }

  Future<void> _loadEarningsData() async {
    setState(() => _isLoading = true);
    
    final data = await ProviderAnalyticsService.getEarningsAnalytics(
      period: _selectedPeriod,
    );
    
    setState(() {
      _earningsData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(106),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          toolbarHeight: 106,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.secondaryGreen,
                  AppColors.secondaryGreen.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondaryGreen.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Earnings Analytics',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Track your revenue growth',
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          leading: Container(
            margin: const EdgeInsets.only(left: 16),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 30.0, 16.0, 16.0),
          child: Column(
            children: [
              // Period selector
              _buildPeriodSelector(),
              const SizedBox(height: 20),
              
              // Statistics summary
              _buildSummaryStats(),
              const SizedBox(height: 20),
              
              // Chart
              _buildChart(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Period',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPeriodButton(
                  'Daily',
                  AnalyticsPeriod.daily,
                  _selectedPeriod == AnalyticsPeriod.daily,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPeriodButton(
                  'Weekly',
                  AnalyticsPeriod.weekly,
                  _selectedPeriod == AnalyticsPeriod.weekly,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPeriodButton(
                  'Monthly',
                  AnalyticsPeriod.monthly,
                  _selectedPeriod == AnalyticsPeriod.monthly,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, AnalyticsPeriod period, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
        _loadEarningsData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.darkGrey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.white : AppColors.darkGrey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStats() {
    if (_isLoading) {
      return _buildLoadingCard();
    }

    if (_earningsData.isEmpty) {
      return _buildEmptyCard('No earnings data available');
    }

    final totalEarnings = _earningsData.fold<double>(
      0, 
      (sum, data) => sum + data.amount,
    );
    
    final averageEarnings = totalEarnings / _earningsData.length;
    final maxEarnings = _earningsData.map((e) => e.amount).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earnings Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total',
                  '\$${totalEarnings.toStringAsFixed(0)}',
                  AppColors.secondaryGreen,
                  Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Average',
                  '\$${averageEarnings.toStringAsFixed(0)}',
                  AppColors.primaryBlue,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Highest',
                  '\$${maxEarnings.toStringAsFixed(0)}',
                  AppColors.red,
                  Icons.star,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.darkGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_isLoading) {
      return _buildLoadingCard();
    }

    if (_earningsData.isEmpty) {
      return _buildEmptyCard('No chart data to display');
    }

    return Container(
      height: 400,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earnings Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxY(),
                backgroundColor: Colors.transparent,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => AppColors.primaryBlue,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${_earningsData[groupIndex].label}\n\$${rod.toY.round()}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _earningsData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _earningsData[index].label,
                              style: TextStyle(
                                color: AppColors.darkGrey,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          '\$${value.toInt()}',
                          style: TextStyle(
                            color: AppColors.darkGrey,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _getMaxY() / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.lightGrey,
                      strokeWidth: 1,
                    );
                  },
                ),
                barGroups: _earningsData.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.amount,
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppColors.primaryBlue.withOpacity(0.8),
                            AppColors.primaryBlue,
                          ],
                        ),
                        width: 24,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              strokeWidth: 3,
            ),
            const SizedBox(height: 12),
            Text(
              'Loading earnings data...',
              style: TextStyle(
                color: AppColors.darkGrey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 40,
              color: AppColors.darkGrey,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: AppColors.darkGrey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  double _getMaxY() {
    if (_earningsData.isEmpty) return 100;
    
    final maxValue = _earningsData.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    return (maxValue * 1.2).ceilToDouble();
  }
}