import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _recognizedText = '';
  DateTime? _selectedTime;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {},
    );

    // Tạo notification channel cho Android với cấu hình tối đa
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'alarm_channel',
      'Báo thức',
      description: 'Kênh thông báo báo thức',
      importance: Importance.max, // Thay đổi từ high sang max
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(channel);

    setState(() {
      _isInitialized = true;
    });
  }

  Future<bool> _requestPermissions() async {
    final results = await [
      Permission.microphone,
      Permission.notification,
      Permission.scheduleExactAlarm,
    ].request();
    
    // Kiểm tra quyền notification
    final notificationStatus = results[Permission.notification];
    if (notificationStatus?.isDenied ?? false) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cần quyền thông báo để đặt báo thức. Vui lòng cấp quyền trong Settings.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
    
    // Kiểm tra quyền schedule exact alarm
    final alarmStatus = results[Permission.scheduleExactAlarm];
    if (alarmStatus?.isDenied ?? false) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cần quyền "Schedule exact alarms" để đặt báo thức chính xác. Vui lòng cấp quyền trong Settings > Apps > Special app access.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
    
    return notificationStatus?.isGranted ?? false;
  }

  Future<void> _startListening() async {
    await _requestPermissions();

    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (error) {
        setState(() {
          _isListening = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${error.errorMsg}')),
        );
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _recognizedText = '';
      });

      await _speech.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'vi_VN', // Sử dụng tiếng Việt
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể truy cập microphone')),
        );
      }
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final now = DateTime.now();
      setState(() {
        _selectedTime = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
        // Nếu thời gian đã qua, đặt cho ngày mai
        if (_selectedTime!.isBefore(now)) {
          _selectedTime = _selectedTime!.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _parseTimeFromText() async {
    if (_recognizedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nói thời gian báo thức')),
      );
      return;
    }

    // Parse thời gian từ text (ví dụ: "7 giờ 30", "7:30", "bảy giờ ba mươi", "bảy giờ rưỡi")
    final text = _recognizedText.toLowerCase();
    int? hour;
    int? minute;

    // Map số tiếng Việt sang số
    final Map<String, int> numberMap = {
      'không': 0, 'một': 1, 'hai': 2, 'ba': 3, 'bốn': 4, 'năm': 5,
      'sáu': 6, 'bảy': 7, 'tám': 8, 'chín': 9, 'mười': 10,
      'mười một': 11, 'mười hai': 12, 'mười ba': 13, 'mười bốn': 14,
      'mười lăm': 15, 'mười sáu': 16, 'mười bảy': 17, 'mười tám': 18,
      'mười chín': 19, 'hai mươi': 20, 'hai mốt': 21, 'hai hai': 22,
      'hai ba': 23, 'hai tư': 24, 'hai lăm': 25, 'hai sáu': 26,
      'hai bảy': 27, 'hai tám': 28, 'hai chín': 29, 'ba mươi': 30,
    };

    // Tìm pattern "X giờ Y" hoặc "X:Y" với số
    final regex = RegExp(r'(\d{1,2})\s*(?:giờ|:)\s*(\d{1,2})');
    final match = regex.firstMatch(text);
    if (match != null) {
      hour = int.tryParse(match.group(1)!);
      minute = int.tryParse(match.group(2)!);
    } else {
      // Thử pattern chỉ có giờ với số
      final hourRegex = RegExp(r'(\d{1,2})\s*giờ');
      final hourMatch = hourRegex.firstMatch(text);
      if (hourMatch != null) {
        hour = int.tryParse(hourMatch.group(1)!);
        // Kiểm tra "rưỡi" hoặc "30"
        if (text.contains('rưỡi')) {
          minute = 30;
        } else {
          minute = 0;
        }
      } else {
        // Thử parse với số tiếng Việt
        for (var entry in numberMap.entries) {
          if (text.contains(entry.key + ' giờ')) {
            hour = entry.value;
            // Kiểm tra phút
            if (text.contains('rưỡi')) {
              minute = 30;
            } else {
              // Tìm phút sau "giờ"
              final minutePattern = RegExp(r'giờ\s+([^\s]+)');
              final minuteMatch = minutePattern.firstMatch(text);
              if (minuteMatch != null) {
                final minuteText = minuteMatch.group(1)!.trim();
                if (numberMap.containsKey(minuteText)) {
                  minute = numberMap[minuteText];
                } else {
                  final minuteNum = int.tryParse(minuteText);
                  if (minuteNum != null) {
                    minute = minuteNum;
                  } else {
                    minute = 0;
                  }
                }
              } else {
                minute = 0;
              }
            }
            break;
          }
        }
      }
    }

    if (hour != null && minute != null && hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
      final now = DateTime.now();
      setState(() {
        _selectedTime = DateTime(
          now.year,
          now.month,
          now.day,
          hour!,
          minute!,
        );
        if (_selectedTime!.isBefore(now)) {
          _selectedTime = _selectedTime!.add(const Duration(days: 1));
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã đặt báo thức: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể nhận dạng thời gian. Vui lòng nói rõ hơn (ví dụ: "7 giờ 30")')),
      );
    }
  }

  Future<void> _testNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Báo thức',
      channelDescription: 'Kênh thông báo báo thức',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      channelShowBadge: true,
      enableLights: true,
      color: const Color.fromARGB(255, 255, 0, 0),
      ticker: 'Báo thức',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      999,
      'Test Báo thức',
      'Nếu bạn nghe thấy thông báo này, hệ thống đang hoạt động!',
      notificationDetails,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi thông báo test. Kiểm tra xem có nghe thấy không?'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _setAlarm() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn thời gian báo thức')),
      );
      return;
    }

    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Báo thức',
      channelDescription: 'Kênh thông báo báo thức',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      channelShowBadge: true,
      enableLights: true,
      color: const Color.fromARGB(255, 255, 0, 0),
      ticker: 'Báo thức',
      ongoing: false,
      autoCancel: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    // Đảm bảo thời gian là tương lai
    final now = DateTime.now();
    DateTime alarmTime = _selectedTime!;
    if (alarmTime.isBefore(now)) {
      alarmTime = alarmTime.add(const Duration(days: 1));
    }
    
    final scheduledDate = tz.TZDateTime.from(alarmTime, tz.local);
    
    // Hủy báo thức cũ trước khi đặt mới
    await _notifications.cancel(0);
    
    try {
      await _notifications.zonedSchedule(
        0,
        'Báo thức',
        'Đã đến giờ báo thức!',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã đặt báo thức lúc ${alarmTime.hour.toString().padLeft(2, '0')}:${alarmTime.minute.toString().padLeft(2, '0')}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi đặt báo thức: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt báo thức'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Thời gian báo thức',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _selectedTime == null
                          ? 'Chưa chọn'
                          : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _selectTime,
                      icon: const Icon(Icons.access_time),
                      label: const Text('Chọn thời gian'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Đặt báo thức bằng giọng nói',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_recognizedText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _recognizedText,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isListening ? _stopListening : _startListening,
                          icon: Icon(_isListening ? Icons.stop : Icons.mic),
                          label: Text(_isListening ? 'Dừng' : 'Bắt đầu nói'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isListening ? Colors.red : Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        if (_recognizedText.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: _parseTimeFromText,
                            icon: const Icon(Icons.check),
                            label: const Text('Xác nhận'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _setAlarm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Đặt báo thức',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _testNotification,
              icon: const Icon(Icons.notifications_active),
              label: const Text('Test Thông báo (Kiểm tra ngay)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

