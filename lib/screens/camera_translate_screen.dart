import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraTranslateScreen extends StatefulWidget {
  const CameraTranslateScreen({super.key});

  @override
  State<CameraTranslateScreen> createState() => _CameraTranslateScreenState();
}

class _CameraTranslateScreenState extends State<CameraTranslateScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _recognizedText = '';
  String _translatedText = '';
  String _sourceLanguage = 'vi';
  String _targetLanguage = 'en';
  
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  OnDeviceTranslator? _translator;
  final OnDeviceTranslatorModelManager _modelManager = OnDeviceTranslatorModelManager();

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
    _initializeCamera();
    _initializeTranslator();
  }

  Future<void> _initializeCamera() async {
    await Permission.camera.request();
    
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _startProcessing();
      }
    }
  }

  Future<void> _initializeTranslator() async {
    try {
      final sourceModel = _getLanguageCode(_sourceLanguage);
      final targetModel = _getLanguageCode(_targetLanguage);
      
      final sourceDownloaded = await _modelManager.isModelDownloaded(_sourceLanguage);
      final targetDownloaded = await _modelManager.isModelDownloaded(_targetLanguage);
      
      if (!sourceDownloaded) {
        await _modelManager.downloadModel(_sourceLanguage);
      }
      if (!targetDownloaded) {
        await _modelManager.downloadModel(_targetLanguage);
      }

      _translator = OnDeviceTranslator(
        sourceLanguage: sourceModel,
        targetLanguage: targetModel,
      );
    } catch (e) {
      // Ignore errors
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

  Future<void> _startProcessing() async {
    if (!_isInitialized || _controller == null || !_controller!.value.isInitialized) {
      return;
    }

    _processFrame();
  }

  Future<void> _processFrame() async {
    if (_isProcessing || !_isInitialized || _controller == null) {
      return;
    }

    try {
      setState(() {
        _isProcessing = true;
      });

      final XFile image = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      String extractedText = '';
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          extractedText += '${line.text}\n';
        }
      }
      
      if (extractedText.trim().isNotEmpty && _translator != null) {
        final translated = await _translator!.translateText(extractedText.trim());
        
        setState(() {
          _recognizedText = extractedText.trim();
          _translatedText = translated;
        });
      } else {
        setState(() {
          _recognizedText = extractedText.trim();
          if (extractedText.trim().isEmpty) {
            _translatedText = '';
          }
        });
      }

      // File ảnh tạm sẽ được xóa tự động

      setState(() {
        _isProcessing = false;
      });

      // Xử lý frame tiếp theo sau 2 giây
      await Future.delayed(const Duration(seconds: 2));
      if (mounted && _isInitialized) {
        _processFrame();
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      // Xử lý frame tiếp theo sau 2 giây
      await Future.delayed(const Duration(seconds: 2));
      if (mounted && _isInitialized) {
        _processFrame();
      }
    }
  }

  Future<void> _updateTranslator() async {
    await _translator?.close();
    await _initializeTranslator();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    _translator?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dịch Realtime từ Camera'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chọn ngôn ngữ
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _sourceLanguage,
                    decoration: const InputDecoration(
                      labelText: 'Từ',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
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
                        _updateTranslator();
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
                      labelText: 'Sang',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
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
                        _updateTranslator();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Camera preview
          Expanded(
            child: _isInitialized && _controller != null
                ? Stack(
                    children: [
                      CameraPreview(_controller!),
                      if (_isProcessing)
                        const Center(
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
          
          // Kết quả nhận dạng và dịch
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_recognizedText.isNotEmpty) ...[
                  const Text(
                    'Text nhận dạng:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _recognizedText,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_translatedText.isNotEmpty) ...[
                  const Text(
                    'Bản dịch:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _translatedText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                if (_recognizedText.isEmpty && _translatedText.isEmpty)
                  const Text(
                    'Đang quét text từ camera...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


