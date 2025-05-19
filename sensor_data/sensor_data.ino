#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>

// ——— Настройки Wi-Fi ———
const char* ssid     = "TP-Link_B181";
const char* password = "qzectbumFer2426";

// ——— Настройки MQTT ———
const char* mqtt_server = "192.168.0.105";  // IP вашего брокера
const uint16_t mqtt_port = 1884;
const char* pub_topic    = "home/dht22";
const char* sub_topics[] = {
  "home/dht22/led21",
  "home/dht22/led22",
  "home/dht22/led23"
};

// ——— Настройки DHT22 ———
#define DHTPIN 4
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);

// ——— Настройки LED ———
const int ledPins[] = {21, 22, 23};

WiFiClient   espClient;
PubSubClient mqttClient(espClient);

void initWiFi() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print('.');
    delay(500);
  }
  Serial.println();
  Serial.print("WiFi connected, IP: ");
  Serial.println(WiFi.localIP());
}

// Обработчик входящих MQTT-сообщений
void mqttCallback(char* topic, byte* payload, unsigned int length) {
  // Определим состояние ON/OFF
  bool on = (length > 0 && payload[0] == '1');

  // Найдём, к какому пину относится топик
  for (int i = 0; i < 3; i++) {
    if (strcmp(topic, sub_topics[i]) == 0) {
      digitalWrite(ledPins[i], on ? HIGH : LOW);
      Serial.printf("LED on pin %d turned %s\n", ledPins[i], on ? "ON" : "OFF");
      break;
    }
  }
}

void reconnectMQTT() {
  while (!mqttClient.connected()) {
    Serial.print("Connecting to MQTT...");
    if (mqttClient.connect("ESP32-DHT22")) {
      Serial.println("connected");
      // После подключения — подписываемся на команды управления LED
      for (auto &t : sub_topics) {
        mqttClient.subscribe(t);
      }
    } else {
      Serial.print("failed, rc=");
      Serial.print(mqttClient.state());
      Serial.println(" — retry in 5s");
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  dht.begin();

  // Настраиваем пины LED как выходы и сразу гасим
  for (int pin : ledPins) {
    pinMode(pin, OUTPUT);
    digitalWrite(pin, LOW);
  }

  initWiFi();
  mqttClient.setServer(mqtt_server, mqtt_port);
  mqttClient.setCallback(mqttCallback);
}

void loop() {
  if (!mqttClient.connected()) {
    reconnectMQTT();
  }
  mqttClient.loop();

  // Чтение данных DHT22
  float temperature = dht.readTemperature();
  float humidity    = dht.readHumidity();

  if (isnan(temperature) || isnan(humidity)) {
    Serial.println("Failed to read from DHT sensor!");
  } else {
    char payload[64];
    int len = snprintf(payload, sizeof(payload),
      "{\"temperature\":%.1f,\"humidity\":%.1f}",
      temperature, humidity
    );

    bool ok = mqttClient.publish(pub_topic, payload, len);
    if (ok) {
      Serial.print("Published: ");
      Serial.println(payload);
    } else {
      Serial.println("Publish failed");
    }
  }

  delay(2000);
}
