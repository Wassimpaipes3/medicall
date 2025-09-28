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

class RatingsAnalyticsScreen extends StatefulWidget {
  const RatingsAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<RatingsAnalyticsScreen> createState() => _RatingsAnalyticsScreenState();
}

class _RatingsAnalyticsScreenState extends State<RatingsAnalyticsScreen> {
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.weekly;
  List<RatingData> _ratingsData = [];
  bool _isLoading = true;
  bool _showPieChart = true;

  @override
  void initState() {
    super.initState();
    _loadRatingsData();
  }

  Future<void> _loadRatingsData() async {
    setState(() => _isLoading = true);
    
    final data = await ProviderAnalyticsService.getRatingsAnalytics(
      period: _selectedPeriod,
    );
    
    setState(() {
      _ratingsData = data;
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
                  const Color(0xFFFF9800),
                  const Color(0xFFFF9800).withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9800).withOpacity(0.3),
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
                  Icons.star_rounded,
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
                      'Ratings Analytics',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Customer feedback',
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
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _showPieChart = !_showPieChart;
                  });
                },
                icon: Icon(
                  _showPieChart ? Icons.bar_chart_rounded : Icons.pie_chart_outline_rounded,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading 
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
                ),
              ),
            )
          : SingleChildScrollView(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.date_range_rounded,
                  color: Color(0xFFFF9800),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Select Time Period',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: AnalyticsPeriod.values.map((period) {
              final isSelected = period == _selectedPeriod;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => _onPeriodChanged(period),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFF9800) : AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFFF9800) : AppColors.darkGrey.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: const Color(0xFFFF9800).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ] : [],
                      ),
                      child: Text(
                        _getPeriodDisplayName(period),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? AppColors.white : AppColors.darkGrey,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats() {
    if (_ratingsData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'No rating data available for this period',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.darkGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final totalRatings = _ratingsData.fold(0, (sum, rating) => sum + rating.count);
    final averageRating = totalRatings > 0 
        ? _ratingsData.fold(0.0, (sum, rating) => sum + (rating.rating * rating.count)) / totalRatings
        : 0.0;
    
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Color(0xFFFF9800),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Rating Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Average Rating',
                  averageRating.toStringAsFixed(1),
                  Icons.star_rounded,
                  const Color(0xFFFF9800),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Total Reviews',
                  totalRatings.toString(),
                  Icons.rate_review_rounded,
                  AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
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
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
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
    if (_ratingsData.isEmpty) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 64,
                color: AppColors.darkGrey,
              ),
              SizedBox(height: 16),
              Text(
                'No data to display',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.darkGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _showPieChart ? Icons.pie_chart_outline_rounded : Icons.bar_chart_rounded,
                      color: const Color(0xFFFF9800),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _showPieChart ? 'Rating Distribution' : 'Rating Breakdown',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: _showPieChart ? _buildPieChart() : _buildBarChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sections: _ratingsData.asMap().entries.map((entry) {
                final index = entry.key;
                final rating = entry.value;
                final colors = [
                  AppColors.red,
                  const Color(0xFFFF9800),
                  const Color(0xFFFFEB3B),
                  AppColors.secondaryGreen,
                  AppColors.primaryBlue,
                ];
                return PieChartSectionData(
                  color: colors[index % colors.length],
                  value: rating.count.toDouble(),
                  title: '${rating.rating}⭐',
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                  badgeWidget: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      rating.count.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colors[index % colors.length],
                      ),
                    ),
                  ),
                  badgePositionPercentageOffset: 1.2,
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _ratingsData.asMap().entries.map((entry) {
              final index = entry.key;
              final rating = entry.value;
              final colors = [
                AppColors.red,
                const Color(0xFFFF9800),
                const Color(0xFFFFEB3B),
                AppColors.secondaryGreen,
                AppColors.primaryBlue,
              ];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${rating.rating} Stars (${rating.count})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.darkGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    final maxCount = _ratingsData.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    
    return BarChart(
      BarChartData(
        maxY: maxCount.toDouble() * 1.2,
        barGroups: _ratingsData.asMap().entries.map((entry) {
          final index = entry.key;
          final rating = entry.value;
          final colors = [
            AppColors.red,
            const Color(0xFFFF9800),
            const Color(0xFFFFEB3B),
            AppColors.secondaryGreen,
            AppColors.primaryBlue,
          ];
          return BarChartGroupData(
            x: rating.rating,
            barRods: [
              BarChartRodData(
                toY: rating.count.toDouble(),
                color: colors[index % colors.length],
                width: 25,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '${value.toInt()}⭐',
                    style: const TextStyle(
                      color: AppColors.darkGrey,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: AppColors.darkGrey,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: AppColors.darkGrey.withOpacity(0.2),
            width: 1,
          ),
        ),
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.darkGrey.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
          drawVerticalLine: false,
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => AppColors.black.withOpacity(0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final rating = _ratingsData.firstWhere((r) => r.rating == group.x);
              return BarTooltipItem(
                '${rating.rating} Stars\n${rating.count} reviews',
                const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _getPeriodDisplayName(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.daily:
        return 'Daily';
      case AnalyticsPeriod.weekly:
        return 'Weekly';
      case AnalyticsPeriod.monthly:
        return 'Monthly';
    }
  }

  void _onPeriodChanged(AnalyticsPeriod period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadRatingsData();
  }
}