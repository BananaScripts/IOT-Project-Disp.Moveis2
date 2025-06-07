import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: const TextTheme(bodyLarge: TextStyle(fontFamily: 'Roboto')),
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

class _EtherHomeState extends State<EtherHome> {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  Map<String, dynamic> sensorData = {};
  Map<String, dynamic> historicoData = {};

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
  }

  void _openSensorSidebar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[850],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Sensor: MQ-2',
                style: TextStyle(fontSize: 22, color: Colors.white),
              ),
              SizedBox(height: 10),
              Text(
                'Detecta: GLP, butano, propano, metano, álcool, hidrogênio e fumaça.',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final buttonSize = size.width * 0.22;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1F1F1F), Color(0xFF2C2C2C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 30),
              Text(
                'ETHER',
                style: TextStyle(
                  color: const Color(0xFF3DF5E2),
                  fontSize: size.width * 0.12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  color: const Color(0xFF2A2A2A),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estado Digital: ${sensorData['estado_digital'] ?? 'N/A'}',
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Valor Analógico: ${sensorData['valor_analogico'] ?? 'N/A'}',
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        const Divider(height: 30, color: Colors.white30),
                        const Text(
                          'Histórico',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        historicoData.isEmpty
                            ? const Text('Nenhum histórico disponível.', style: TextStyle(color: Colors.white70))
                            : SizedBox(
                                height: 150,
                                child: ListView(
                                  children: historicoData.entries.map((entry) {
                                    final ts = entry.key;
                                    final item = entry.value as Map;
                                    return ListTile(
                                      title: Text(
                                        '[$ts]',
                                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                                      ),
                                      subtitle: Text(
                                        'Digital: ${item['estado_digital'] ?? 'N/A'}  |  Analógico: ${item['valor_analogico'] ?? 'N/A'}',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(
                      icon: Icons.arrow_back,
                      label: 'Voltar',
                      color: const Color(0xFF3DF5E2),
                      size: buttonSize,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.local_gas_station,
                      label: 'Sensor',
                      color: const Color(0xFFFF6961),
                      size: buttonSize,
                      onPressed: () {},
                    ),
                    _buildActionButton(
                      icon: Icons.menu,
                      label: 'Menu',
                      color: const Color(0xFFFFE97F),
                      size: buttonSize,
                      onPressed: () => _openSensorSidebar(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required double size,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: Icon(icon, color: Colors.black, size: size * 0.4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
