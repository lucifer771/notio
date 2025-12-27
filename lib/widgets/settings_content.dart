import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:notio/services/storage_service.dart';
import 'package:notio/services/localization_service.dart';
import 'package:notio/utils/languages.dart';
import 'package:notio/utils/translations.dart';
import 'package:notio/screens/archive_screen.dart';
import 'package:notio/screens/trash_screen.dart';
import 'dart:ui'; // For BoxBlur

class SettingsContent extends StatefulWidget {
  const SettingsContent({super.key});

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  // Use a ValueNotifier to listen to Theme changes locally if needed,
  // but main app handles global theme. Here we just update UI.

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: StorageService().themeNotifier,
        builder: (context, isDark, child) {
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'settings'.tr,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    // --- Appearance Section ---
                    _buildGlassTile(
                      isDark: isDark,
                      icon: Icons.language,
                      title: 'language'.tr,
                      subtitle: LocalizationService
                          .currentLocale.value.languageCode
                          .toUpperCase(),
                      onTap: () {
                        _showLanguageSelector(context);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildGlassTile(
                      isDark: isDark,
                      icon: isDark ? Icons.light_mode : Icons.dark_mode,
                      title: 'dark_mode'.tr,
                      trailing: Switch(
                        value: isDark,
                        activeColor: const Color(0xFF6C63FF),
                        onChanged: (val) {
                          StorageService().toggleTheme(val);
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- Features Section ---
                    _buildGlassTile(
                      isDark: isDark,
                      icon: Icons.archive_outlined,
                      title: 'archived_notes'.tr,
                      subtitle: 'view_archived'.tr,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ArchiveScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildGlassTile(
                      isDark: isDark,
                      icon: Icons.delete_outline,
                      title: 'trash'.tr,
                      subtitle: 'recover_deleted'.tr,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const TrashScreen()),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // --- Features Section Continued ---
                    _buildGlassTile(
                      isDark: isDark,
                      icon: Icons.lock_outline,
                      title: 'app_lock'.tr,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('coming_soon'.tr)),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildGlassTile(
                      isDark: isDark,
                      icon: Icons.notifications_outlined,
                      title: 'notifications'.tr,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('coming_soon'.tr)),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildGlassTile(
                      isDark: isDark,
                      icon: Icons.backup_outlined,
                      title: 'backup_restore'.tr,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('coming_soon'.tr)),
                        );
                      },
                    ),

                    const SizedBox(height: 40),
                    Center(
                      child: Text(
                        "NOTIO v1.0.0",
                        style: TextStyle(
                          color: isDark ? Colors.white24 : Colors.black26,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  ].animate(interval: 50.ms).fadeIn().slideY(begin: 0.1),
                ),
              ),
            ],
          );
        });
  }

  Widget _buildGlassTile({
    required bool isDark,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              onTap: onTap,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
                      : const Color(0xFF6C63FF).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF6C63FF)),
              ),
              title: Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: subtitle != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : null,
              trailing: trailing ??
                  Icon(Icons.chevron_right,
                      color: isDark ? Colors.white24 : Colors.black26),
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _LanguageSelectionSheet(),
    );
  }
}

class _LanguageSelectionSheet extends StatefulWidget {
  const _LanguageSelectionSheet();

  @override
  State<_LanguageSelectionSheet> createState() =>
      _LanguageSelectionSheetState();
}

class _LanguageSelectionSheetState extends State<_LanguageSelectionSheet> {
  String _searchQuery = "";
  List<LanguageConfig> _filteredLanguages = LanguageConfig.supportedLanguages;

  @override
  Widget build(BuildContext context) {
    final isDark = StorageService().themeNotifier.value;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'select_language'.tr,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'search'.tr,
                hintStyle:
                    TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                prefixIcon: Icon(Icons.search,
                    color: isDark ? Colors.white54 : Colors.black54),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                  _filteredLanguages = LanguageConfig.supportedLanguages
                      .where((lang) =>
                          lang.name.toLowerCase().contains(_searchQuery) ||
                          lang.nativeName.toLowerCase().contains(_searchQuery))
                      .toList();
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredLanguages.length,
              itemBuilder: (context, index) {
                final lang = _filteredLanguages[index];
                final isSelected =
                    LocalizationService.currentLocale.value.languageCode ==
                        lang.code;

                return ListTile(
                  onTap: () {
                    LocalizationService.changeLocale(lang.code);
                    Navigator.pop(context); // Close sheet
                  },
                  title: Text(lang.name),
                  subtitle: Text(lang.nativeName,
                      style: TextStyle(color: Colors.grey)),
                  leading: Text(
                    lang.flag,
                    style: const TextStyle(fontSize: 24),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Color(0xFF6C63FF))
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
