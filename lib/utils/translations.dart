import 'package:notio/services/localization_service.dart';

class AppTranslations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'settings': 'Settings',
      'search_notes': 'Search notes...',
      'tags': 'Tags',
      'organize_notes': 'Organize your notes',
      'no_tags': 'No tags yet',
      'create_first_tag': 'Create your first tag',
      'no_notes': 'No notes yet. Tap + to create one!',
      'no_notes_tag': 'No notes found with this tag.',
      'hello': 'Hello',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'notifications': 'Notifications',
      'other_features': 'Other Features',
      'backup_notes': 'Backup Notes',
      'restore_notes': 'Restore Notes',
      'archived_notes': 'Archived Notes',
      'trash': 'Trash',
      'appearance': 'Appearance',
      'general': 'General',
      'privacy_security': 'Privacy & Security',
      'about': 'About',
      'get_started': 'Get Started',
      'whats_your_name': "What's your name?",
      'enter_name': 'Enter your name',
      'write_smarter': 'Write Smarter.',
      'on': 'On',
      'off': 'Off',
      'manage_alerts': 'Manage alerts',
      'save_locally': 'Save locally',
      'restore_backup': 'Restore from backup',
      'view_archived': 'View archived notes',
      'recover_deleted': 'Recover deleted notes',
      'note_deleted': 'Note deleted',
      'undo': 'Undo',
      'pinned': 'Pinned',
      'locked': 'Locked',
      'create_new_tag': 'Create New Tag',
      'tag_name': 'Tag Name',
      'cancel': 'Cancel',
      'create': 'Create',
      'rename': 'Rename',
      'change_color': 'Change Color',
      'delete_tag': 'Delete Tag',
      'less': 'Less',
      'more': 'More',
    },
    'es': {
      'settings': 'Ajustes',
      'search_notes': 'Buscar notas...',
      'tags': 'Etiquetas',
      'organize_notes': 'Organiza tus notas',
      'no_tags': 'Sin etiquetas',
      'create_first_tag': 'Crea tu primera etiqueta',
      'no_notes': 'No hay notas. ¡Toca + para crear una!',
      'no_notes_tag': 'No hay notas con esta etiqueta.',
      'hello': 'Hola',
      'dark_mode': 'Modo Oscuro',
      'language': 'Idioma',
      'notifications': 'Notificaciones',
      'other_features': 'Otras Características',
      'backup_notes': 'Copia de Seguridad',
      'restore_notes': 'Restaurar Notas',
      'archived_notes': 'Notas Archivadas',
      'trash': 'Papelera',
      'appearance': 'Apariencia',
      'general': 'General',
      'privacy_security': 'Privacidad y Seguridad',
      'about': 'Acerca de',
      'get_started': 'Comenzar',
      'whats_your_name': '¿Cómo te llamas?',
      'enter_name': 'Ingresa tu nombre',
      'write_smarter': 'Escribe mejor.',
      'on': 'Encendido',
      'off': 'Apagado',
      'manage_alerts': 'Gestionar alertas',
      'save_locally': 'Guardar localmente',
      'restore_backup': 'Restaurar de copia',
      'view_archived': 'Ver notas archivadas',
      'recover_deleted': 'Recuperar notas borradas',
      'note_deleted': 'Nota eliminada',
      'undo': 'Deshacer',
      'pinned': 'Fijado',
      'locked': 'Bloqueado',
      'create_new_tag': 'Crear Nueva Etiqueta',
      'tag_name': 'Nombre de Etiqueta',
      'cancel': 'Cancelar',
      'create': 'Crear',
      'rename': 'Renombrar',
      'change_color': 'Cambiar Color',
      'delete_tag': 'Eliminar Etiqueta',
      'less': 'Menos',
      'more': 'Más',
    },
    // We can add more languages here.
    // For 72 languages, we would dynamically load or map them.
    // Currently defaulting to English for generic fallback in logic below.
  };

  static String text(String key) {
    // Get current language code
    final locale = LocalizationService.currentLocale.value.languageCode;

    // Check if translation exists for current locale
    if (_localizedValues.containsKey(locale) &&
        _localizedValues[locale]!.containsKey(key)) {
      return _localizedValues[locale]![key]!;
    }

    // Fallback to English
    return _localizedValues['en']![key] ?? key;
  }
}

extension StringTranslation on String {
  String get tr => AppTranslations.text(this);
}
