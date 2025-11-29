import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import '../screens/camera_translate_screen.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final TextEditingController _textController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();
  
  String _translatedText = '';
  bool _isTranslating = false;
  bool _isListening = false;
  String _recognizedText = '';
  String _sourceLanguage = 'vi';
  String _targetLanguage = 'en';
  
  final List<Map<String, String>> _languages = [
    {'code': 'vi', 'name': 'Tiếng Việt'},
    {'code': 'en', 'name': 'English'},
    {'code': 'zh', 'name': '中文'},
    {'code': 'ja', 'name': '日本語'},
    {'code': 'ko', 'name': '한국어'},
    {'code': 'fr', 'name': 'Français'},
    {'code': 'es', 'name': 'Español'},
  ];

  @override
  void initState() {
    super.initState();
    _downloadModels();
  }

  Future<void> _downloadModels() async {
    try {
      final sourceDownloaded = await _modelManager.isModelDownloaded(_sourceLanguage);
      final targetDownloaded = await _modelManager.isModelDownloaded(_targetLanguage);
      
      if (!sourceDownloaded) {
        await _modelManager.downloadModel(_sourceLanguage);
      }
      if (!targetDownloaded) {
        await _modelManager.downloadModel(_targetLanguage);
      }
    } catch (e) {
      // Ignore errors, models will be downloaded on first use
    }
  }

  TranslateLanguage _getLanguageCode(String code) {
    switch (code) {
      case 'vi':
        return TranslateLanguage.vietnamese;
      case 'en':
        return TranslateLanguage.english;
      case 'zh':
        return TranslateLanguage.chinese;
      case 'ja':
        return TranslateLanguage.japanese;
      case 'ko':
        return TranslateLanguage.korean;
      case 'fr':
        return TranslateLanguage.french;
      case 'es':
        return TranslateLanguage.spanish;
      default:
        return TranslateLanguage.english;
    }
  }

  Future<void> _translateText(String text) async {
    if (text.isEmpty) {
      setState(() {
        _translatedText = '';
      });
      return;
    }

    setState(() {
      _isTranslating = true;
    });

    try {
      final sourceLang = _getLanguageCode(_sourceLanguage);
      final targetLang = _getLanguageCode(_targetLanguage);

      final translator = OnDeviceTranslator(
        sourceLanguage: sourceLang,
        targetLanguage: targetLang,
      );

      final translated = await translator.translateText(text);
      
      setState(() {
        _translatedText = translated;
        _isTranslating = false;
      });

      await translator.close();
    } catch (e) {
      setState(() {
        _translatedText = 'Lỗi: $e';
        _isTranslating = false;
      });
    }
  }

  Future<void> _startListening() async {
    await Permission.microphone.request();
    
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
            _textController.text = result.recognizedWords;
          });
          if (result.finalResult) {
            _translateText(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
    if (_recognizedText.isNotEmpty) {
      _translateText(_recognizedText);
    }
  }

  Future<void> _pickImage() async {
    await Permission.camera.request();
    await Permission.photos.request();
    
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    
    if (image != null) {
      await _extractTextFromImage(image.path);
    }
  }

  Future<void> _pickImageFromGallery() async {
    await Permission.photos.request();
    
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      await _extractTextFromImage(image.path);
    }
  }

  Future<void> _extractTextFromImage(String imagePath) async {
    setState(() {
      _isTranslating = true;
      _translatedText = 'Đang nhận dạng text...';
    });

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      String extractedText = '';
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          extractedText += '${line.text}\n';
        }
      }
      
      await textRecognizer.close();
      
      setState(() {
        _textController.text = extractedText.trim();
      });
      
      if (extractedText.trim().isNotEmpty) {
        await _translateText(extractedText.trim());
      } else {
        setState(() {
          _translatedText = 'Không tìm thấy text trong ảnh';
          _isTranslating = false;
        });
      }
    } catch (e) {
      setState(() {
        _translatedText = 'Lỗi: $e';
        _isTranslating = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dịch thuật'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Chọn ngôn ngữ
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _sourceLanguage,
                    decoration: const InputDecoration(
                      labelText: 'Ngôn ngữ nguồn',
                      border: OutlineInputBorder(),
                    ),
                    items: _languages.map((lang) {
                      return DropdownMenuItem(
                        value: lang['code'],
                        child: Text(lang['name']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sourceLanguage = value;
                        });
                        _downloadModels();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_forward),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _targetLanguage,
                    decoration: const InputDecoration(
                      labelText: 'Ngôn ngữ đích',
                      border: OutlineInputBorder(),
                    ),
                    items: _languages.map((lang) {
                      return DropdownMenuItem(
                        value: lang['code'],
                        child: Text(lang['name']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _targetLanguage = value;
                        });
                        _downloadModels();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Nhập text
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Nhập text để dịch',
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(_isListening ? Icons.stop : Icons.mic),
                      onPressed: _isListening ? _stopListening : _startListening,
                      color: _isListening ? Colors.red : Colors.blue,
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: _pickImage,
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo_library),
                      onPressed: _pickImageFromGallery,
                    ),
                  ],
                ),
              ),
              maxLines: 5,
              onChanged: (text) {
                if (text.isNotEmpty) {
                  _translateText(text);
                } else {
                  setState(() {
                    _translatedText = '';
                  });
                }
              },
            ),
            if (_isListening)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _recognizedText.isEmpty ? 'Đang nghe...' : _recognizedText,
                  style: TextStyle(
                    color: Colors.blue,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            
            // Nút camera realtime
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CameraTranslateScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Dịch Realtime từ Camera'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            
            // Kết quả dịch
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kết quả dịch:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_isTranslating)
                    const Center(child: CircularProgressIndicator())
                  else
                    Text(
                      _translatedText.isEmpty ? 'Chưa có kết quả' : _translatedText,
                      style: const TextStyle(fontSize: 16),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

