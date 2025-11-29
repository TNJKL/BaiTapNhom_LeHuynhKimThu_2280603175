import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _phoneController = TextEditingController(
    text: '0797619239',
  );

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      _showSnackBar('Vui lòng nhập số điện thoại');
      return;
    }

    // Yêu cầu quyền gọi điện
    final status = await Permission.phone.request();
    if (!status.isGranted) {
      _showSnackBar('Cần quyền gọi điện để thực hiện chức năng này');
      return;
    }

    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Không thể mở ứng dụng gọi điện');
      }
    } catch (e) {
      _showSnackBar('Lỗi: $e');
    }
  }

  Future<void> _openYouTube() async {
    try {
      // Thử mở YouTube app với URL scheme đúng
      final Uri youtubeAppUri = Uri.parse('https://www.youtube.com');
      
      // Thử mở app trước
      if (await canLaunchUrl(youtubeAppUri)) {
        // Thử với intent YouTube
        try {
          final Uri intentUri = Uri.parse('intent://www.youtube.com/#Intent;scheme=https;package=com.google.android.youtube;end');
          if (await canLaunchUrl(intentUri)) {
            await launchUrl(intentUri);
            return;
          }
        } catch (e) {
          // Nếu không được, thử cách khác
        }
        
        // Thử với vnd.youtube scheme
        try {
          final Uri vndUri = Uri.parse('vnd.youtube://');
          if (await canLaunchUrl(vndUri)) {
            await launchUrl(vndUri);
            return;
          }
        } catch (e) {
          // Tiếp tục với web
        }
        
        // Mở web YouTube
        await launchUrl(youtubeAppUri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Không thể mở YouTube');
      }
    } catch (e) {
      _showSnackBar('Lỗi: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cá nhân'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 40),
              // TextField để nhập số điện thoại
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  hintText: 'Nhập số điện thoại',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  _makePhoneCall(_phoneController.text.trim());
                },
                icon: const Icon(Icons.phone),
                label: const Text('Gọi điện'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  minimumSize: const Size(200, 50),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _openYouTube,
                icon: const Icon(Icons.play_circle),
                label: const Text('Mở YouTube'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  minimumSize: const Size(200, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}






