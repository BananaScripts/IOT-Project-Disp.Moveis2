import 'package:flutter/material.dart';

void main() {
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
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Roboto'),
        ),
      ),
      home: const EtherHome(),
    );
  }
}

class EtherHome extends StatelessWidget {
  const EtherHome({super.key});

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
    final buttonSize = size.width * 0.22; // Responsivo

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
                    height: size.height * 0.35,
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    child: const Center(
                      child: Text(
                        'Informações sobre o gás aqui...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
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
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
