import 'package:flutter/material.dart';
import 'member_profile_screen.dart';

class GroupInfoScreen extends StatelessWidget {
  const GroupInfoScreen({super.key});

  final List<Map<String, dynamic>> _members = const [
    {
      'name': 'Lê Huỳnh Kim Thư',
      'id': '2280603175',
      'role': 'Thành viên',
      'avatarPath': 'assets/images/kimthu_rabbit.png', // Ảnh con thỏ
    },
    {
      'name': 'Lê Hữu Trí',
      'id': '2280603357',
      'role': 'Thành viên',
      'avatarPath': null, // Sẽ dùng network image
    },
    {
      'name': 'Lương Vĩ',
      'id': '2180603734',
      'role': 'Thành viên',
      'avatarPath': null, // Sẽ dùng network image
    },
    {
      'name': 'Nguyễn Thị Trà My',
      'id': '2280601981',
      'role': 'Thành viên',
      'avatarPath': null, // Sẽ dùng network image
    },
  ];

  Widget _buildAvatar(String? avatarPath, String name, BuildContext context) {
    if (avatarPath != null) {
      // Nếu có ảnh local, dùng Image.asset với errorBuilder
      return ClipOval(
        child: Image.asset(
          avatarPath,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback nếu không load được ảnh
            final initials = name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join();
            return CircleAvatar(
              radius: 30,
              backgroundColor: _getColorForName(name),
              child: Text(
                initials.toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      );
    } else {
      // Nếu không có ảnh, dùng CircleAvatar với chữ cái đầu
      final initials = name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join();
      return CircleAvatar(
        radius: 30,
        backgroundColor: _getColorForName(name),
        child: Text(
          initials.toUpperCase(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
  }

  Color _getColorForName(String name) {
    // Tạo màu dựa trên tên để mỗi người có màu khác nhau
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin nhóm'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              children: [
                const Icon(
                  Icons.group,
                  size: 60,
                  color: Colors.blue,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Nhóm Lập trình Mobile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_members.length} thành viên',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: _buildAvatar(
                      member['avatarPath'] as String?,
                      member['name'] as String,
                      context,
                    ),
                    title: Text(
                      member['name'] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'MSSV: ${member['id']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          'Vai trò: ${member['role']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MemberProfileScreen(member: member),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
