import 'dart:ui';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:fl_chart/fl_chart.dart'; // Adicione este import no topo do arquivo

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const EtherApp());
}

class EtherApp extends StatelessWidget {
  const EtherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ETHER',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Roboto', letterSpacing: 1.2),
        ),
      ),
      home: const EtherHome(),
    );
  }
}

class EtherHome extends StatefulWidget {
  const EtherHome({super.key});

  @override
  _EtherHomeState createState() => _EtherHomeState();
}

class _EtherHomeState extends State<EtherHome> with SingleTickerProviderStateMixin {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  Map<String, dynamic> sensorData = {};
  Map<String, dynamic> historicoData = {};

  // Adicione estes controladores e variáveis para o filtro
  final TextEditingController _filterController = TextEditingController();
  String _filterType = 'digital'; // 'digital' ou 'analogico'
  String _filterValue = '';

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _databaseReference.child("sensor_gas").onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          sensorData = Map<String, dynamic>.from(data);
          historicoData = data['historico'] != null
              ? Map<String, dynamic>.from(data['historico'])
              : {};
        });
      } else {
        setState(() {
          sensorData = {};
          historicoData = {};
        });
      }
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _filterController.dispose(); // Dispose do controller do filtro
    super.dispose();
  }

  void _openSensorSidebar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              color: Colors.white.withOpacity(0.07),
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Sensor: MQ-2',
                    style: TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Detecta: GLP, butano, propano, metano, álcool, hidrogênio e fumaça.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openChartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final historicoList = historicoData.entries.map((entry) {
          final ts = entry.key;
          final item = entry.value as Map;
          return {
            'timestamp': ts,
            'digital': int.tryParse('${item['estado_digital'] ?? '0'}') ?? 0,
            'analogico': double.tryParse('${item['valor_analogico'] ?? '0'}') ?? 0.0,
          };
        }).toList();

        historicoList.sort((a, b) => (a['timestamp'].toString()).compareTo(b['timestamp'].toString()));

        // Use MediaQuery para responsividade
        final mq = MediaQuery.of(context);
        final chartWidth = mq.size.width * 0.92;
        final chartHeight = mq.size.height * 0.45;

        return Dialog(
          backgroundColor: Colors.black.withOpacity(0.85),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: chartWidth,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Fluxo dos Dados por Tempo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: chartHeight,
                  width: chartWidth,
                  child: historicoList.isEmpty
                      ? const Center(
                          child: Text(
                            'Sem dados suficientes para o gráfico.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : LineChart(
                          LineChartData(
                            backgroundColor: Colors.transparent,
                            gridData: FlGridData(show: true, drawVerticalLine: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    if (idx < 0 || idx >= historicoList.length) return const SizedBox();
                                    final ts = historicoList[idx]['timestamp'].toString();
                                    // Mostra apenas parte do timestamp para não poluir
                                    return Text(
                                      ts.length > 8 ? ts.substring(ts.length - 8) : ts,
                                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                                    );
                                  },
                                  interval: (historicoList.length / 5).ceilToDouble().clamp(1, double.infinity),
                                ),
                              ),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: true, border: Border.all(color: Colors.white24)),
                            minX: 0,
                            maxX: (historicoList.length - 1).toDouble(),
                            minY: 0,
                            maxY: historicoList.map((e) => e['analogico'] as double).fold<double>(0, (prev, el) => el > prev ? el : prev) + 10,
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  for (int i = 0; i < historicoList.length; i++)
                                    FlSpot(i.toDouble(), historicoList[i]['analogico'] as double),
                                ],
                                isCurved: true,
                                color: Colors.blueAccent.shade100,
                                barWidth: 3,
                                dotData: FlDotData(show: false),
                              ),
                              LineChartBarData(
                                spots: [
                                  for (int i = 0; i < historicoList.length; i++)
                                    FlSpot(i.toDouble(), (historicoList[i]['digital'] as int).toDouble()),
                                ],
                                isCurved: false,
                                color: Colors.cyanAccent,
                                barWidth: 2,
                                dotData: FlDotData(show: false),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 18, height: 4, color: Colors.blueAccent.shade100),
                    const SizedBox(width: 8),
                    const Text('Analógico', style: TextStyle(color: Colors.white70)),
                    const SizedBox(width: 18),
                    Container(width: 18, height: 4, color: Colors.cyanAccent),
                    const SizedBox(width: 8),
                    const Text('Digital', style: TextStyle(color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final buttonSize = size.width * 0.22;

    // Lógica de filtro para o histórico
    final filteredHistorico = _filterValue.isEmpty
        ? historicoData
        : historicoData.map((k, v) => MapEntry(k, v)).entries.where((entry) {
            final item = entry.value as Map;
            final valueToCheck = _filterType == 'digital'
                ? '${item['estado_digital'] ?? ''}'
                : '${item['valor_analogico'] ?? ''}';
            return valueToCheck.contains(_filterValue);
          }).fold<Map<String, dynamic>>({}, (map, entry) {
            map[entry.key] = entry.value;
            return map;
          });

    return Scaffold(
      body: Stack(
        children: [
          // Fundo preto para garantir contraste
          Container(color: Colors.black),
          // ModelViewer como fundo
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.centerRight, // Alinha o modelo à direita
                child: SizedBox(
                  width: size.width * 0.8, // Ajusta a largura do modelo
                  child: ModelViewer(
                    src: 'assets/Weather_Station_in_th_0624193936_texture.glb',
                    alt: "Weather Station 3D",
                    ar: false,
                    autoRotate: true,
                    cameraControls: false,
                    backgroundColor: Colors.transparent,
                    disableZoom: true,
                    fieldOfView: "2deg",
                    cameraOrbit: "30deg 75deg 9.5m", // Zoom e leve rotação
                  ),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0F2027).withOpacity(0.7),
                      const Color(0xFF2C5364).withOpacity(0.7),
                      const Color(0xFF3DF5E2).withOpacity(0.13),
                      const Color(0xFF232526).withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [
                      0.0,
                      0.5 + 0.2 * _controller.value,
                      0.8,
                      1.0,
                    ],
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return const LinearGradient(
                                colors: [Color(0xFF3DF5E2), Color(0xFF00C9FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds);
                            },
                            child: Text(
                              'ETHER',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: size.width * 0.13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 6,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ),
                        ),
                        // Botão de "?" azul
                        _buildNeonButton(
                          icon: Icons.help_outline,
                          label: '',
                          color: const Color(0x6AB8E6),
                          size: size.width * 0.05,
                          onPressed: () => _openSensorSidebar(context),
                        ),
                        const SizedBox(width: 10),
                        // Botão de gráfico
                        _buildNeonButton(
                          icon: Icons.show_chart,
                          label: '',
                          color: Colors.blueAccent, // Outro tom de azul
                          size: size.width * 0.05,
                          onPressed: () => _openChartDialog(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      'Trabalho desenvolvido pelo grupo BananaScript na Matéria de Programação de Dispositivos Móveis 2, com foco na coleta e apresentação de de dados coletados.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.local_gas_station, color: Colors.cyanAccent.shade100, size: 32),
                              const SizedBox(width: 10),
                              Text(
                                'Sensor MQ-2',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.92),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _buildInfoRow(
                            label: 'Estado Digital',
                            value: '${sensorData['estado_digital'] ?? 'N/A'}',
                            color: Colors.greenAccent,
                          ),
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            label: 'Valor Analógico',
                            value: '${sensorData['valor_analogico'] ?? 'N/A'}',
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(height: 18),
                          // Filtro do histórico
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _filterController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Filtrar valor...',
                                    hintStyle: const TextStyle(color: Colors.white54),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.08),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _filterValue = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              DropdownButton<String>(
                                value: _filterType,
                                dropdownColor: Colors.black87,
                                style: const TextStyle(color: Colors.white),
                                borderRadius: BorderRadius.circular(12),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'digital',
                                    child: Text('Digital'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'analogico',
                                    child: Text('Analógico'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _filterType = value;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Divider(
                            height: 30,
                            color: Colors.white.withOpacity(0.18),
                            thickness: 1.2,
                          ),
                          const Text(
                            'Histórico',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          filteredHistorico.isEmpty
                              ? const Text(
                                  'Nenhum histórico disponível.',
                                  style: TextStyle(color: Colors.white54, fontSize: 15),
                                )
                              : SizedBox(
                                  height: 160,
                                  child: ListView(
                                    children: filteredHistorico.entries.map((entry) {
                                      final ts = entry.key;
                                      final item = entry.value as Map;
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: Icon(Icons.timeline, color: Colors.cyanAccent.shade100, size: 22),
                                        title: Text(
                                          '[$ts]',
                                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                                        ),
                                        subtitle: Text(
                                          'Digital: ${item['estado_digital'] ?? 'N/A'}  |  Analógico: ${item['valor_analogico'] ?? 'N/A'}',
                                          style: const TextStyle(color: Colors.white, fontSize: 13),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required String label, required String value, required Color color}) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildNeonButton({
    required IconData icon,
    required String label,
    required Color color,
    required double size,
    required VoidCallback onPressed,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonSize = (constraints.maxWidth < 100)
            ? constraints.maxWidth * 0.7
            : size;
        return Column(
          children: [
            SizedBox(
              width: buttonSize,
              height: buttonSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.7),
                      blurRadius: 18,
                      spreadRadius: 1,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.withOpacity(0.92),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                  ),
                  child: Icon(icon, color: Colors.black, size: buttonSize * 0.45),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
            ),
          ],
        );
      },
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.13),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
