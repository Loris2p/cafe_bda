import 'package:cafe_bda/models/stats_data.dart';
import 'package:cafe_bda/providers/cafe_data_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  late Future<StatsData> _statsFuture;

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  void _refreshStats() {
    setState(() {
      _statsFuture = context.read<CafeDataProvider>().getStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Statistiques & Rapports",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshStats,
                  tooltip: "Actualiser",
                )
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<StatsData>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Erreur: ${snapshot.error}"));
                  }
                  
                  final stats = snapshot.data ?? StatsData.empty();
                  
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        // KPI Cards
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _KpiCard(
                              title: "Cafés Servis",
                              value: stats.totalCoffeesServed.toString(),
                              icon: Icons.coffee,
                              color: Colors.brown,
                            ),
                            _KpiCard(
                              title: "Revenu Total",
                              value: "${stats.totalRevenue.toStringAsFixed(2)} €",
                              icon: Icons.attach_money,
                              color: Colors.blue,
                            ),
                            _KpiCard(
                              title: "Crédits Chargés",
                              value: "${stats.totalCreditsAmount.toStringAsFixed(2)} €",
                              icon: Icons.euro,
                              color: Colors.green,
                            ),
                            _KpiCard(
                              title: "Cafés Offerts",
                              value: stats.totalFidelityCoffees.toString(),
                              icon: Icons.card_giftcard,
                              color: Colors.purple,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Charts Section
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 800;
                            return Flex(
                              direction: isWide ? Axis.horizontal : Axis.vertical,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Pie Chart: Payment Methods
                                SizedBox(
                                  width: isWide ? constraints.maxWidth * 0.4 : double.infinity,
                                  height: 300,
                                  child: _ChartCard(
                                    title: "Moyens de Paiement",
                                    child: _PaymentMethodsChart(data: stats.coffeesByPaymentMethod),
                                  ),
                                ),
                                if (isWide) const SizedBox(width: 16) else const SizedBox(height: 16),
                                // Bar Chart: Popular Coffees
                                Expanded(
                                  child: SizedBox(
                                    height: 300,
                                    child: _ChartCard(
                                      title: "Top Cafés",
                                      child: _PopularCoffeesChart(data: stats.popularCoffees),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                        ),
                        const SizedBox(height: 16),
                        
                        // Line Chart: Sales Over Time
                        SizedBox(
                          height: 300,
                          child: _ChartCard(
                            title: "Évolution des Ventes (Cafés)",
                            child: _SalesLineChart(data: stats.salesOverTime),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: 200,
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
              Text(title, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

// --- Charts Implementations ---

class _PaymentMethodsChart extends StatefulWidget {
  final Map<String, int> data;

  const _PaymentMethodsChart({required this.data});

  @override
  State<_PaymentMethodsChart> createState() => _PaymentMethodsChartState();
}

class _PaymentMethodsChartState extends State<_PaymentMethodsChart> {

  bool _showPieChart = true;

  int touchedIndex = -1;



  @override

  Widget build(BuildContext context) {

    if (widget.data.isEmpty) return const Center(child: Text("Pas de données"));



    final total = widget.data.values.fold(0, (sum, val) => sum + val);

    // Palette

    final colors = [

      Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple, Colors.teal

    ];



    // Conversion des données en liste pour indexation stable

    final entries = widget.data.entries.toList();



    return Stack(

      children: [

        _showPieChart 

                                    ? PieChart(

                                        PieChartData(

                                          pieTouchData: PieTouchData(

                                            touchCallback: (FlTouchEvent event, pieTouchResponse) {

                                              setState(() {

                                                if (!event.isInterestedForInteractions ||

                                                    pieTouchResponse == null ||

                                                    pieTouchResponse.touchedSection == null) {

                                                  touchedIndex = -1;

                                                  return;

                                                }

                                                touchedIndex = pieTouchResponse

                                                    .touchedSection!.touchedSectionIndex;

                                              });

                                            },

                                          ),

                                          sections: entries.asMap().entries.map((entryIndex) {

                                            final index = entryIndex.key;

                                            final entry = entryIndex.value;

                                            final isTouched = index == touchedIndex;

                                            final fontSize = isTouched ? 14.0 : 12.0;

                                            final radius = isTouched ? 90.0 : 80.0;

                                            final percentage = (entry.value / total * 100).toStringAsFixed(1);

                                            final color = colors[index % colors.length];

                                            

                                            final title = isTouched 

                                                ? '${entry.key}\n${entry.value} (${percentage}%)' 

                                                : '${entry.key}\n$percentage%';

                        

                                            return PieChartSectionData(

                                              color: color,

                                              value: entry.value.toDouble(),

                                              title: title,

                                              radius: radius,

                                              titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white),

                                            );

                                          }).toList(),

                                          sectionsSpace: 2,

                                          centerSpaceRadius: 30,

                                        ),

                                      )

                                    : BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (entries.map((e) => e.value).reduce((curr, next) => curr > next ? curr : next) * 1.2).toDouble(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                     getTooltipColor: (_) => Colors.blueGrey,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value.toInt() >= 0 && value.toInt() < entries.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              entries[value.toInt()].key,
                              style: const TextStyle(fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: entries.asMap().entries.map((entryIndex) {
                  final index = entryIndex.key;
                  final entry = entryIndex.value;
                  final color = colors[index % colors.length];

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.toDouble(),
                        color: color,
                        width: 30,
                        borderRadius: BorderRadius.circular(4),
                      )
                    ],
                  );
                }).toList(),
              ),
            ),
        // Bouton de bascule
        Positioned(
          right: 0,
          top: 0,
          child: IconButton(
            icon: Icon(
              _showPieChart ? Icons.bar_chart : Icons.pie_chart, 
              color: Colors.grey,
            ),
            tooltip: _showPieChart ? "Voir en diagramme à barres" : "Voir en camembert",
            onPressed: () {
              setState(() {
                _showPieChart = !_showPieChart;
              });
            },
          ),
        ),
      ],
    );
  }
}

class _PopularCoffeesChart extends StatefulWidget {
  final Map<String, int> data;

  const _PopularCoffeesChart({required this.data});

  @override
  State<_PopularCoffeesChart> createState() => _PopularCoffeesChartState();
}

class _PopularCoffeesChartState extends State<_PopularCoffeesChart> {
  bool _showBarChart = true;
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const Center(child: Text("Pas de données"));

    // Sort by popularity and take top 5
    final sortedEntries = widget.data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Descending
    final topEntries = sortedEntries.take(5).toList();
    final total = topEntries.fold(0, (sum, e) => sum + e.value);

    // Palette cohérente
    final colors = [
      Theme.of(context).primaryColor,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.redAccent,
    ];

    return Stack(
      children: [
        _showBarChart 
        ? BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (topEntries.first.value * 1.2).toDouble(),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                   getTooltipColor: (_) => Colors.blueGrey,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value.toInt() >= 0 && value.toInt() < topEntries.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            topEntries[value.toInt()].key,
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: topEntries.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.value.toDouble(),
                      color: colors[entry.key % colors.length],
                      width: 20,
                      borderRadius: BorderRadius.circular(4),
                    )
                  ],
                );
              }).toList(),
            ),
          )
        : PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = pieTouchResponse
                        .touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sections: topEntries.asMap().entries.map((entryIndex) {
                final index = entryIndex.key;
                final entry = entryIndex.value;
                final isTouched = index == touchedIndex;
                final fontSize = isTouched ? 14.0 : 12.0;
                final radius = isTouched ? 90.0 : 80.0;
                final percentage = (entry.value / total * 100).toStringAsFixed(1);
                final color = colors[index % colors.length];
                
                final title = isTouched 
                    ? '${entry.key}\n${entry.value} (${percentage}%)' 
                    : '${entry.key}\n$percentage%';
                
                return PieChartSectionData(
                  color: color,
                  value: entry.value.toDouble(),
                  title: title,
                  radius: radius,
                  titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
            ),
          ),
        // Bouton de bascule
        Positioned(
          right: 0,
          top: 0,
          child: IconButton(
            icon: Icon(
              _showBarChart ? Icons.pie_chart : Icons.bar_chart, 
              color: Colors.grey,
            ),
            tooltip: _showBarChart ? "Voir en camembert" : "Voir en diagramme à barres",
            onPressed: () {
              setState(() {
                _showBarChart = !_showBarChart;
              });
            },
          ),
        ),
      ],
    );
  }
}

class _SalesLineChart extends StatelessWidget {
  final List<DailyStat> data;

  const _SalesLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text("Pas de données"));
    if (data.length < 2) return const Center(child: Text("Pas assez de données pour une courbe"));

    final points = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    final maxY = data.map((e) => e.value).reduce((curr, next) => curr > next ? curr : next);

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.blueGrey,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final flSpot = barSpot;
                final index = flSpot.x.toInt();
                if (index < 0 || index >= data.length) return null;

                final date = DateFormat('dd/MM/yyyy').format(data[index].date);
                return LineTooltipItem(
                  '$date \n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: flSpot.y.toInt().toString(),
                      style: const TextStyle(
                        color: Colors.yellow,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    const TextSpan(
                      text: ' cafés',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (data.length / 5).ceilToDouble(), // Show ~5 labels
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                   return Padding(
                     padding: const EdgeInsets.only(top: 8.0),
                     child: Text(
                       DateFormat('dd/MM').format(data[index].date),
                       style: const TextStyle(fontSize: 10),
                     ),
                   );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Simplify
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: maxY * 1.1,
        lineBarsData: [
          LineChartBarData(
            spots: points,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}
