class LanguageConfig {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const LanguageConfig({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });

  static const List<LanguageConfig> supportedLanguages = [
    LanguageConfig(
        code: 'en', name: 'English', nativeName: 'English', flag: '🇺🇸'),
    LanguageConfig(
        code: 'es', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
    LanguageConfig(
        code: 'fr', name: 'French', nativeName: 'Français', flag: '🇫🇷'),
    LanguageConfig(
        code: 'de', name: 'German', nativeName: 'Deutsch', flag: '🇩🇪'),
    LanguageConfig(
        code: 'it', name: 'Italian', nativeName: 'Italiano', flag: '🇮🇹'),
    LanguageConfig(
        code: 'pt', name: 'Portuguese', nativeName: 'Português', flag: '🇵🇹'),
    LanguageConfig(
        code: 'ru', name: 'Russian', nativeName: 'Русский', flag: '🇷🇺'),
    LanguageConfig(code: 'zh', name: 'Chinese', nativeName: '中文', flag: '🇨🇳'),
    LanguageConfig(
        code: 'ja', name: 'Japanese', nativeName: '日本語', flag: '🇯🇵'),
    LanguageConfig(code: 'ko', name: 'Korean', nativeName: '한국어', flag: '🇰🇷'),
    LanguageConfig(
        code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳'),
    LanguageConfig(
        code: 'ar', name: 'Arabic', nativeName: 'العربية', flag: '🇸🇦'),
    LanguageConfig(
        code: 'tr', name: 'Turkish', nativeName: 'Türkçe', flag: '🇹🇷'),
    LanguageConfig(
        code: 'nl', name: 'Dutch', nativeName: 'Nederlands', flag: '🇳🇱'),
    LanguageConfig(
        code: 'pl', name: 'Polish', nativeName: 'Polski', flag: '🇵🇱'),
  ];
}
