// lib/core/constants/app_constants.dart

class AppConstants {
  // App info
  static const appName = 'LinkVault';
  static const appVersion = '1.0.0';

  // Hive box names
  static const linksBox = 'links_box';
  static const groupsBox = 'groups_box';
  static const vaultBox = 'vault_box';
  static const settingsBox = 'settings_box';
  static const recentBox = 'recent_box';

  // Secure storage keys
  static const vaultPasswordKey = 'vault_password_hash';
  static const encryptionKeyKey = 'encryption_key';
  static const biometricEnabledKey = 'biometric_enabled';
  static const vaultLockedAtKey = 'vault_locked_at';

  // Settings keys
  static const themeKey = 'theme';
  static const onboardingCompleteKey = 'onboarding_complete';

  // Vault
  static const vaultAutoLockMinutes = 5;
  static const maxRecentLinks = 10;
  static const maxFrequentLinks = 5;

  // Auto-suggestion keywords → group
  static const Map<String, String> urlKeywordGroups = {
    'github': 'GitHub',
    'gitlab': 'GitLab',
    'bitbucket': 'Git',
    'api': 'APIs',
    'docs': 'Docs',
    'documentation': 'Docs',
    'stackoverflow': 'Dev Resources',
    'medium': 'Articles',
    'notion': 'Workspace',
    'figma': 'Design',
    'dribbble': 'Design',
    'youtube': 'Videos',
    'twitter': 'Social',
    'linkedin': 'Social',
    'reddit': 'Social',
    'slack': 'Tools',
    'discord': 'Tools',
    'trello': 'Tools',
    'jira': 'Tools',
    'vercel': 'Deployment',
    'netlify': 'Deployment',
    'aws': 'Cloud',
    'cloud': 'Cloud',
    'npm': 'Packages',
    'pub.dev': 'Packages',
    'pypi': 'Packages',
  };

  // Metadata fetch timeout
  static const metadataFetchTimeout = Duration(seconds: 8);
}

class HiveTypeIds {
  static const link = 0;
  static const group = 1;
  static const vaultEntry = 2;
  static const recentLink = 3;
}
