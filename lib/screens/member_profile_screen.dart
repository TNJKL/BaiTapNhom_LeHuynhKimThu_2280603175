import 'package:flutter/material.dart';

class MemberProfileScreen extends StatelessWidget {
  final Map<String, dynamic> member;

  const MemberProfileScreen({
    super.key,
    required this.member,
  });

  Color _getColorForName(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    final index = name.hashCode % colors.length;
    return colors[index.abs()];
  }

  @override
  Widget build(BuildContext context) {
    final name = member['name'] as String;
    final id = member['id'] as String;
    final role = member['role'] as String;
    final avatarPath = member['avatarPath'] as String?;
    
    // Thông tin giả cho mỗi thành viên
    final Map<String, Map<String, String>> fakeProfiles = {
      'Lê Huỳnh Kim Thư': {
        'email': 'kimthu.le@student.hcmus.edu.vn',
        'phone': '0797619239',
        'birthday': '15/03/2004',
        'address': 'TP. Hồ Chí Minh',
        'hobby': 'Lập trình, Đọc sách, Nghe nhạc',
        'skill': 'Flutter, Dart, Java, Python',
        'bio': 'Sinh viên năm 3 chuyên ngành Công nghệ thông tin. Đam mê phát triển ứng dụng mobile và học hỏi công nghệ mới.',
      },
      'Lê Hữu Trí': {
        'email': 'letri.huu@student.hcmus.edu.vn',
        'phone': '0123456789',
        'birthday': '20/05/2003',
        'address': 'TP. Hồ Chí Minh',
        'hobby': 'Chơi game, Xem phim, Du lịch',
        'skill': 'Flutter, React Native, JavaScript',
        'bio': 'Sinh viên năm 3 với niềm đam mê phát triển ứng dụng di động. Thích khám phá các framework mới và chia sẻ kiến thức.',
      },
      'Lương Vĩ': {
        'email': 'luongvi@student.hcmus.edu.vn',
        'phone': '0987654321',
        'birthday': '10/08/2003',
        'address': 'TP. Hồ Chí Minh',
        'hobby': 'Thể thao, Lập trình, Nhiếp ảnh',
        'skill': 'Flutter, Android Native, Kotlin',
        'bio': 'Sinh viên năm 3 yêu thích phát triển ứng dụng Android. Có kinh nghiệm với Android SDK và Flutter framework.',
      },
      'Nguyễn Thị Trà My': {
        'email': 'tramy.nguyen@student.hcmus.edu.vn',
        'phone': '0912345678',
        'birthday': '25/12/2003',
        'address': 'TP. Hồ Chí Minh',
        'hobby': 'Vẽ tranh, Đọc sách, Nấu ăn',
        'skill': 'Flutter, UI/UX Design, Figma',
        'bio': 'Sinh viên năm 3 với đam mê thiết kế giao diện người dùng. Kết hợp giữa lập trình và thiết kế để tạo ra những ứng dụng đẹp mắt.',
      },
    };

    final profile = fakeProfiles[name] ?? {
      'email': 'student@hcmus.edu.vn',
      'phone': '0000000000',
      'birthday': '01/01/2000',
      'address': 'TP. Hồ Chí Minh',
      'hobby': 'Lập trình',
      'skill': 'Flutter',
      'bio': 'Sinh viên đại học.',
    };

    Widget buildAvatar() {
      if (avatarPath != null) {
        return ClipOval(
          child: Image.asset(
            avatarPath,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback nếu không load được ảnh
              final initials = name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join();
              return CircleAvatar(
                radius: 60,
                backgroundColor: _getColorForName(name),
                child: Text(
                  initials.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        );
      } else {
        final initials = name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join();
        return CircleAvatar(
          radius: 60,
          backgroundColor: _getColorForName(name),
          child: Text(
            initials.toUpperCase(),
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin thành viên'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header với ảnh đại diện
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  buildAvatar(),
                  const SizedBox(height: 20),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Thông tin chi tiết
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(
                    context,
                    'Thông tin cá nhân',
                    [
                      _buildInfoRow(Icons.badge, 'MSSV', id),
                      _buildInfoRow(Icons.email, 'Email', profile['email']!),
                      _buildInfoRow(Icons.phone, 'Số điện thoại', profile['phone']!),
                      _buildInfoRow(Icons.cake, 'Ngày sinh', profile['birthday']!),
                      _buildInfoRow(Icons.location_on, 'Địa chỉ', profile['address']!),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoCard(
                    context,
                    'Sở thích & Kỹ năng',
                    [
                      _buildInfoRow(Icons.favorite, 'Sở thích', profile['hobby']!),
                      _buildInfoRow(Icons.code, 'Kỹ năng', profile['skill']!),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoCard(
                    context,
                    'Giới thiệu',
                    [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          profile['bio']!,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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

