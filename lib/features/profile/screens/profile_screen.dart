import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../../services/unit_service.dart';
import '../../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _userService = UserService();
  final _picker = ImagePicker();

  AppUser? _userData;
  bool _isLoading = true;
  bool _isUploading = false;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final user = await _userService.getUser();
    if (mounted) {
      setState(() {
        _userData = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (image == null) return;

    setState(() {
      _profileImage = File(image.path);
      _isUploading = true;
    });

    final url = await _userService.uploadProfileImage(_profileImage!);
    if (mounted) {
      setState(() => _isUploading = false);
      if (url != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );
        _loadProfile();
      }
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0A1F18) : const Color(0xFFF2F7F4);
    final cardColor = isDark ? const Color(0xFF112D24) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F291E);
    final subTextColor = isDark ? Colors.grey[500] : Colors.grey[600];
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71), strokeWidth: 2)),
      );
    }

    final name = _userData?.name ?? 'Hiker';
    final email = _userData?.email ?? '';

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // Header banner
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 32),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                boxShadow: isDark ? [] : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: _isUploading ? null : _pickAndUploadImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: const Color(0xFF2ECC71).withValues(alpha: 0.12),
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!) as ImageProvider
                              : (_userData?.photoUrl != null
                                  ? NetworkImage(_userData!.photoUrl!)
                                  : null),
                          child: (_profileImage == null && _userData?.photoUrl == null)
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'H',
                                  style: const TextStyle(
                                    color: Color(0xFF2ECC71),
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : null,
                        ),
                        if (_isUploading)
                          const CircularProgressIndicator(
                              color: Color(0xFF2ECC71), strokeWidth: 2),
                        if (!_isUploading)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2ECC71),
                                shape: BoxShape.circle,
                                border: Border.all(color: cardColor, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_outlined,
                                  size: 14, color: Colors.black),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(fontSize: 13, color: subTextColor),
                  ),

                  const SizedBox(height: 24),

                  // Stats row
                  Row(
                    children: [
                      _StatTile(
                        value: '${_userData?.totalHikes ?? 0}',
                        label: 'Hikes',
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      _buildDivider(borderColor),
                      ValueListenableBuilder<DistanceUnit>(
                        valueListenable: UnitService.distanceUnitNotifier,
                        builder: (context, _, __) {
                          return _StatTile(
                            value: UnitService.formatDistanceValue(_userData?.totalDistance ?? 0.0),
                            label: UnitService.distanceSymbol,
                            textColor: textColor,
                            subTextColor: subTextColor,
                          );
                        },
                      ),
                      _buildDivider(borderColor),
                      _StatTile(
                        value: '${_userData?.speciesSpotted ?? 0}',
                        label: 'Species',
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Menu section
                _buildSectionLabel('Activity', subTextColor),
                const SizedBox(height: 8),
                _buildMenuCard([
                  _MenuItem(
                    icon: Icons.history_rounded,
                    label: 'Hike History',
                    onTap: () => context.push('/hike-history'),
                  ),
                  _MenuItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Statistics',
                    onTap: () => context.push('/user-statistics'),
                  ),
                ], cardColor, textColor, borderColor),

                const SizedBox(height: 20),

                _buildSectionLabel('Preferences', subTextColor),
                const SizedBox(height: 8),
                _buildMenuCard([
                  _MenuItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => context.push('/settings'),
                  ),
                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notifications set to default')),
                      );
                    },
                  ),
                ], cardColor, textColor, borderColor),

                const SizedBox(height: 28),

                // Logout
                GestureDetector(
                  onTap: _logout,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: const Center(
                      child: Text(
                        'Sign Out',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(Color color) {
    return Container(width: 1, height: 36, color: color);
  }

  Widget _buildSectionLabel(String text, Color? subTextColor) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: subTextColor,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildMenuCard(List<_MenuItem> items, Color cardColor, Color textColor, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: const Color(0xFF2ECC71), size: 18),
                ),
                title: Text(
                  item.label,
                  style: TextStyle(color: textColor, fontSize: 14),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[500],
                  size: 20,
                ),
                onTap: item.onTap,
              ),
              if (i < items.length - 1)
                Divider(
                  height: 1,
                  color: borderColor,
                  indent: 56,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color textColor;
  final Color? subTextColor;

  const _StatTile({
    required this.value,
    required this.label,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: subTextColor)),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label, required this.onTap});
}
