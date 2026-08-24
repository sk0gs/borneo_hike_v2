import 'package:flutter/material.dart';
import '../../../services/theme_service.dart';
import '../../../services/unit_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showDistanceUnitPicker(BuildContext context, Color cardColor, Color textColor, Color? subTextColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ValueListenableBuilder<DistanceUnit>(
          valueListenable: UnitService.distanceUnitNotifier,
          builder: (context, currentUnit, _) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'Select Distance Unit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: const Icon(Icons.straighten_rounded, color: Color(0xFF2ECC71)),
                      title: Text('Metric (Kilometers - km)', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                      subtitle: Text('Used worldwide (1 km = 1,000 meters)', style: TextStyle(color: subTextColor, fontSize: 12)),
                      trailing: currentUnit == DistanceUnit.metric
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2ECC71))
                          : null,
                      onTap: () {
                        UnitService.setDistanceUnit(DistanceUnit.metric);
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: const Icon(Icons.square_foot_rounded, color: Color(0xFF2ECC71)),
                      title: Text('Imperial (Miles - mi)', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                      subtitle: Text('Used in US/UK (1 mi ≈ 1.61 km)', style: TextStyle(color: subTextColor, fontSize: 12)),
                      trailing: currentUnit == DistanceUnit.imperial
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2ECC71))
                          : null,
                      onTap: () {
                        UnitService.setDistanceUnit(DistanceUnit.imperial);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTempUnitPicker(BuildContext context, Color cardColor, Color textColor, Color? subTextColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ValueListenableBuilder<TemperatureUnit>(
          valueListenable: UnitService.tempUnitNotifier,
          builder: (context, currentUnit, _) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'Select Temperature Unit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: const Icon(Icons.thermostat_rounded, color: Color(0xFF2ECC71)),
                      title: Text('Celsius (°C)', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                      subtitle: Text('Standard metric temperature scale', style: TextStyle(color: subTextColor, fontSize: 12)),
                      trailing: currentUnit == TemperatureUnit.celsius
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2ECC71))
                          : null,
                      onTap: () {
                        UnitService.setTemperatureUnit(TemperatureUnit.celsius);
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: const Icon(Icons.device_thermostat_rounded, color: Color(0xFF2ECC71)),
                      title: Text('Fahrenheit (°F)', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                      subtitle: Text('Imperial temperature scale', style: TextStyle(color: subTextColor, fontSize: 12)),
                      trailing: currentUnit == TemperatureUnit.fahrenheit
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2ECC71))
                          : null,
                      onTap: () {
                        UnitService.setTemperatureUnit(TemperatureUnit.fahrenheit);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0A1F18) : const Color(0xFFF2F7F4);
    final cardColor = isDark ? const Color(0xFF112D24) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F291E);
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeService.themeModeNotifier,
        builder: (context, currentMode, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('APPEARANCE', subTextColor),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      _buildThemeTile(
                        context: context,
                        mode: ThemeMode.system,
                        currentMode: currentMode,
                        title: 'System Default',
                        subtitle: 'Match system dark or light preference',
                        icon: Icons.brightness_auto_rounded,
                        isFirst: true,
                        isLast: false,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        borderColor: borderColor,
                      ),
                      _buildThemeTile(
                        context: context,
                        mode: ThemeMode.light,
                        currentMode: currentMode,
                        title: 'Light Mode',
                        subtitle: 'Bright theme for daytime outdoor reading',
                        icon: Icons.wb_sunny_rounded,
                        isFirst: false,
                        isLast: false,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        borderColor: borderColor,
                      ),
                      _buildThemeTile(
                        context: context,
                        mode: ThemeMode.dark,
                        currentMode: currentMode,
                        title: 'Dark Mode',
                        subtitle: 'Rainforest dark theme (battery friendly)',
                        icon: Icons.dark_mode_rounded,
                        isFirst: false,
                        isLast: true,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        borderColor: borderColor,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                _buildSectionHeader('PREFERENCES & UNITS', subTextColor),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      ValueListenableBuilder<DistanceUnit>(
                        valueListenable: UnitService.distanceUnitNotifier,
                        builder: (context, distUnit, _) {
                          final label = distUnit == DistanceUnit.metric
                              ? 'Metric (km)'
                              : 'Imperial (mi)';
                          return _buildSelectableTile(
                            icon: Icons.straighten_rounded,
                            title: 'Distance Units',
                            value: label,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            borderColor: borderColor,
                            showDivider: true,
                            onTap: () => _showDistanceUnitPicker(context, cardColor, textColor, subTextColor),
                          );
                        },
                      ),
                      ValueListenableBuilder<TemperatureUnit>(
                        valueListenable: UnitService.tempUnitNotifier,
                        builder: (context, tempUnit, _) {
                          final label = tempUnit == TemperatureUnit.celsius
                              ? 'Celsius (°C)'
                              : 'Fahrenheit (°F)';
                          return _buildSelectableTile(
                            icon: Icons.thermostat_rounded,
                            title: 'Temperature Units',
                            value: label,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            borderColor: borderColor,
                            showDivider: false,
                            onTap: () => _showTempUnitPicker(context, cardColor, textColor, subTextColor),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                _buildSectionHeader('ABOUT', subTextColor),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      _buildInfoTile(
                        icon: Icons.info_outline_rounded,
                        title: 'Application Version',
                        value: 'v1.0.0',
                        textColor: textColor,
                        subTextColor: subTextColor,
                        borderColor: borderColor,
                        showDivider: true,
                      ),
                      _buildInfoTile(
                        icon: Icons.eco_rounded,
                        title: 'BorneoHike Safety',
                        value: 'Active Protection Enabled',
                        textColor: textColor,
                        subTextColor: subTextColor,
                        borderColor: borderColor,
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color? color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildThemeTile({
    required BuildContext context,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isFirst,
    required bool isLast,
    required Color textColor,
    required Color? subTextColor,
    required Color borderColor,
  }) {
    final isSelected = currentMode == mode;
    const activeColor = Color(0xFF2ECC71);

    return Column(
      children: [
        InkWell(
          onTap: () => ThemeService.setThemeMode(mode),
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(16) : Radius.zero,
            bottom: isLast ? const Radius.circular(16) : Radius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor.withValues(alpha: 0.15)
                        : (subTextColor?.withValues(alpha: 0.08) ?? Colors.grey.withValues(alpha: 0.1)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? activeColor : subTextColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? activeColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? activeColor : (subTextColor ?? Colors.grey),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.black)
                      : null,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 54,
            color: borderColor,
          ),
      ],
    );
  }

  Widget _buildSelectableTile({
    required IconData icon,
    required String title,
    required String value,
    required Color textColor,
    required Color? subTextColor,
    required Color borderColor,
    required bool showDivider,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: const Color(0xFF2ECC71), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2ECC71),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.unfold_more_rounded,
                  color: subTextColor,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 54,
            color: borderColor,
          ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required Color textColor,
    required Color? subTextColor,
    required Color borderColor,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: subTextColor?.withValues(alpha: 0.08) ?? Colors.grey.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: subTextColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2ECC71),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 54,
            color: borderColor,
          ),
      ],
    );
  }
}
