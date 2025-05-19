import 'package:flutter/material.dart';
import 'mqtt_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final MqttService _mqtt;
  double? _temp, _hum;
  bool _connected = false;
  String _status = 'Connecting…';
  final Map<int, bool> _ledState = {21: false, 22: false, 23: false};

  @override
  void initState() {
    super.initState();
    _mqtt = MqttService();
    _mqtt.connect().then((_) {
      setState(() {
        _connected = true;
        _status = 'Connected';
      });
    }).catchError((e) {
      setState(() => _status = 'Error: $e');
    });
    _mqtt.dataStream.listen((data) {
      setState(() {
        _temp = data['temperature'];
        _hum  = data['humidity'];
      });
    });
  }

  @override
  void dispose() {
    _mqtt.dispose();
    super.dispose();
  }

  Widget _buildSensorCard() {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSensorColumn(Icons.thermostat, 'Температура', _temp, '°C'),
            _buildSensorColumn(Icons.water_drop, 'Влажность', _hum, '%'),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorColumn(IconData icon, String label, double? value, String unit) {
    return Column(
      children: [
        Icon(icon, size: 32, color: unit == '°C' ? Colors.redAccent : Colors.blueAccent),
        SizedBox(height: 8),
        AnimatedSwitcher(
          duration: Duration(milliseconds: 500),
          child: Text(
            value != null ? '${value.toStringAsFixed(1)} $unit' : '--',
            key: ValueKey(value),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildLedControlCard() {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: _ledState.keys.map((pin) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Свет $pin', style: TextStyle(fontSize: 18)),
                Switch(
                  value: _ledState[pin]!,
                  onChanged: _connected
                      ? (val) {
                          _mqtt.publishLed(pin, val);
                          setState(() => _ledState[pin] = val);
                        }
                      : null,
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('DHT22 & LEDs')),
      body: SafeArea(
        child: _connected
            ? SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSensorCard(),
                    _buildLedControlCard(),
                  ],
                ),
              )
            : Center(child: Text(_status)),
      ),
    );
  }
}