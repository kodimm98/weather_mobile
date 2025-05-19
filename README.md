# DHT22 + MQTT + ESP32 + Flutter

Проект демонстрирует считывание температуры и влажности с датчика DHT22 на плате ESP32, передачу данных по MQTT (Mosquitto) и отображение их в мобильном приложении на Flutter. Кроме того, приложение позволяет управлять тремя светодиодами, подключёнными к пинам ESP32.

---

## 📋 Описание проекта

![PXL_20250519_105301319](https://github.com/user-attachments/assets/504f7d21-8e30-4dd5-adce-4c959d098755)


* **ESP32** читает показания с **DHT22** (AM2302) каждые 2 секунды и публикует их в виде JSON в топик `home/dht22` на MQTT-брокере.
* **Flutter-приложение** подписывается на этот топик и в реальном времени отображает текущие значения температуры и влажности.
* Приложение также отправляет команды (`"1"`/`"0"`) в топики:

  * `home/dht22/led21`
  * `home/dht22/led22`
  * `home/dht22/led23`
    для управления тремя светодиодами.

---

## 🔧 Используемые компоненты

* **MCU**: ESP32 DevKit
* **Датчик**: DHT22
* **Светодиоды**: 3 × LED + резисторы 220 Ω
* **MQTT-брокер**: Mosquitto
* **Мобильное приложение**: Flutter + пакет `mqtt_client`

---

## 🔌 Схема подключения

|  Компонент | ESP32-пин | Питание |
| :--------: | :-------: | :-----: |
|  DHT22 VCC |    3V3    |  3.3 В  |
|  DHT22 GND |    GND    |   0 В   |
| DHT22 DATA |   GPIO 4  |         |
|    LED 1   |  GPIO 21  |         |
|    LED 2   |  GPIO 22  |         |
|    LED 3   |  GPIO 23  |         |

---

## 🚀 Инструкция по запуску

### 1. Настройка MQTT-брокера Mosquitto

1. Установите Mosquitto:

   * Ubuntu: `sudo apt install mosquitto`
   * macOS: `brew install mosquitto`
2. Если нужно разрешить внешние подключения, создайте файл `remote.conf` в `/etc/mosquitto/conf.d/` со следующим содержимым:

   ```conf
   listener 1884
   allow_anonymous true
   ```
3. Перезапустите сервис:

   ```bash
   sudo systemctl restart mosquitto
   ```

### 2. Прошивка ESP32

1. Откройте в Arduino IDE папку `sensor_data` и файл `sensor_data.ino`.
2. Установите библиотеки:

   * **DHT sensor library**
   * **PubSubClient**
3. В скетче задайте ваши параметры:

   ```cpp
   const char* ssid        = "YOUR_SSID";
   const char* password    = "YOUR_PASSWORD";
   const char* mqtt_server = "192.168.x.x";  // IP вашего брокера
   const uint16_t mqtt_port = 1884;
   ```
4. Загрузите код на ESP32.

### 3. Запуск Flutter-приложения

1. Убедитесь, что установлен Flutter SDK: [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
2. Перейдите в папку `flutter_app/`:

   ```bash
   cd flutter_app
   flutter pub get
   ```
3. В файле `lib/mqtt_service.dart` проверьте настройки брокера:

   ```dart
   final _client = MqttServerClient.withPort(
     '192.168.x.x',    // IP брокера
     'flutter_client', // clientId
     1884,             // порт
   );
   ```
4. Подключите устройство (Android/iOS) или запустите эмулятор и выполните:

   ```bash
   flutter run -d <device_id>
   ```

---

## 📱 Скриншоты приложения
![Screenshot_20250519-195906](https://github.com/user-attachments/assets/40660459-c047-4f99-a9bd-6404e896a672)
![Screenshot_20250519-200501](https://github.com/user-attachments/assets/bbe59737-9225-4068-8d91-5f744437464d)

---

## 📝 Автор
kodimm98
