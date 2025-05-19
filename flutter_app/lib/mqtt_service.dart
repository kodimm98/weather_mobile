import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final _client = MqttServerClient.withPort(
    '192.168.0.105',  // IP вашего брокера
    'flutter_client', // уникальный clientId
    1884,             // порт MQTT
  );
  final _dataCtrl = StreamController<Map<String, double>>.broadcast();

  Stream<Map<String, double>> get dataStream => _dataCtrl.stream;

  MqttService() {
    _client.logging(on: false);
    _client.keepAlivePeriod = 20;
    _client.onDisconnected = _onDisconnected;
  }

  Future<void> connect() async {
    try {
      await _client.connect();
    } catch (e) {
      _client.disconnect();
      rethrow;
    }
    _client.subscribe('home/dht22', MqttQos.atMostOnce);
    _client.updates!.listen(_onMessage);
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage?>>? messages) {
    final rec = messages![0].payload as MqttPublishMessage;
    final payload =
        MqttPublishPayload.bytesToStringAsString(rec.payload.message);
    final data = json.decode(payload) as Map<String, dynamic>;
    _dataCtrl.add({
      'temperature': (data['temperature'] as num).toDouble(),
      'humidity':    (data['humidity']    as num).toDouble(),
    });
  }

  /// Публикует команду управления LED на топик `home/dht22/led<pin>`
  void publishLed(int pin, bool on) {
    final topic = 'home/dht22/led$pin';
    final builder = MqttClientPayloadBuilder();
    builder.addString(on ? '1' : '0');
    _client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
  }

  void _onDisconnected() {}

  void dispose() {
    _client.disconnect();
    _dataCtrl.close();
  }
}