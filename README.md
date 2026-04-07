# 🔐 LinkVault

> A production-ready personal link & credential manager for Android — built with Flutter, Riverpod, Supabase, and AES-256 encryption.

---

## ✨ Features

| Category | Details |
|---|---|
| **Links** | Add / edit / delete links with auto-fetch title + description from URL metadata |
| **Groups** | Create colour-coded groups (GitHub, APIs, Tools…), filter links per group |
| **Search** | Real-time search across title, URL, description |
| **Favorites** | Star any link, dedicated favourites section on Home |
| **Suggestions** | Recently opened, frequently used, auto-group suggestion from URL keywords |
| **Vault** | Separate AES-256 encrypted credential store — locked behind master password |
| **Biometrics** | Fingerprint / face unlock for the vault (optional) |
| **Offline** | Hive local-first storage — full offline support, auto-sync to Supabase |
| **Security** | EncryptedSharedPreferences, HTTPS-only, ProGuard, clipboard auto-clear |

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.22+ |
| State management | Riverpod 2.x (AsyncNotifier) |
| Local DB | Hive Flutter |
| Cloud sync | Supabase (PostgreSQL + anonymous auth) |
| Secure storage | flutter_secure_storage (EncryptedSharedPreferences) |
| Encryption | AES-256-CBC via `encrypt` package |
| Biometrics | local_auth |
| Animations | flutter_animate |
| URL open | url_launcher |
| Metadata scrape | Custom HTTP scraper (OG tags) |

---

## 🚀 Getting Started

### 1. Prerequisites

```bash
flutter --version   # 3.22.0 or later
java --version      # 17 or later  (for Android build)
```

### 2. Clone & Install

```bash
git clone https://github.com/your-org/linkvault.git
cd linkvault
flutter pub get
```

### 3. Configure Environment

Copy `.env` and fill in your values:

```bash
cp .env .env.local   # keep .env as the template — Flutter loads .env
```

Edit `.env`:

```dotenv
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
ENCRYPTION_KEY=exactly32characterslongsecretkey
```

> ⚠️ The `ENCRYPTION_KEY` **must be exactly 32 characters** for AES-256.

### 4. Supabase Setup

In your Supabase project, open the **SQL Editor** and run the schema at the bottom of
`lib/services/supabase_service.dart`. It creates:

- `links` — link records with RLS
- `groups` — group records with RLS
- `vault_entries` — encrypted credentials with RLS

Enable **Anonymous sign-in** under Authentication → Providers → Anonymous.

### 5. Generate Hive Adapters

```bash
dart run build_runner build --delete-conflicting-outputs
```

> The `.g.dart` files included in the repo are pre-written equivalents — the generator will overwrite them identically.

### 6. Add Fonts (Optional — defaults to system font)

Download **Sora** from Google Fonts and place into `assets/fonts/`:

```
assets/fonts/
  Sora-Regular.ttf
  Sora-Medium.ttf
  Sora-SemiBold.ttf
  Sora-Bold.ttf
```

Or remove the `fonts:` block from `pubspec.yaml` to use the system sans-serif.

### 7. Run

```bash
# Debug
flutter run

# Release APK
flutter build apk --release --split-per-abi

# Release AAB (Play Store)
flutter build appbundle --release
```

---

## 🔑 Release Signing

1. **Generate a keystore:**

```bash
keytool -genkeypair \
  -v \
  -keystore android/keystore.jks \
  -alias linkvault \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

2. **Create `android/key.properties`:**

```properties
storeFile=keystore.jks
storePassword=your-store-password
keyAlias=linkvault
keyPassword=your-key-password
```

> ⚠️ Add `android/key.properties` and `android/keystore.jks` to `.gitignore`.

3. **Build signed AAB:**

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## 🏗 Project Structure

```
lib/
├── main.dart                         # Bootstrap — Hive, Supabase, Encryption, Riverpod
├── main_scaffold.dart                # Shell — 5-tab bottom nav
├── core/
│   ├── constants/app_constants.dart  # Box names, type IDs, keyword→group map
│   ├── errors/failures.dart          # Sealed Failure types + Result<T>
│   ├── router/app_router.dart        # Named route generator
│   └── utils/url_utils.dart          # URL normalise, domain extract, group suggest
├── theme/
│   └── app_theme.dart                # ThemeData, AppColors, AppSpacing, AppRadius
├── services/
│   ├── encryption_service.dart       # AES-256-CBC + SHA-256 password hash
│   ├── supabase_service.dart         # Supabase client + SQL schema
│   ├── biometric_service.dart        # local_auth wrapper
│   └── metadata_service.dart         # HTTP OG/meta scraper
├── widgets/
│   ├── glass/glass_card.dart         # GlassCard, AccentGlassCard
│   └── common/
│       ├── app_search_bar.dart       # Search + EmptyState + SectionHeader + FaviconWidget
│       ├── offline_banner.dart       # Connectivity monitor
│       └── password_strength_indicator.dart
└── features/
    ├── links/
    │   ├── domain/entities/link_entity.dart
    │   ├── data/repositories/links_repository.dart
    │   └── presentation/
    │       ├── providers/links_providers.dart
    │       ├── pages/home_screen.dart
    │       ├── pages/all_links_screen.dart
    │       ├── pages/add_edit_link_screen.dart
    │       └── widgets/link_list_item.dart
    ├── groups/
    │   ├── domain/entities/group_entity.dart
    │   ├── data/repositories/groups_repository.dart
    │   └── presentation/
    │       ├── providers/groups_providers.dart
    │       ├── pages/groups_screen.dart
    │       └── pages/group_links_screen.dart
    ├── vault/
    │   ├── domain/entities/vault_entry_entity.dart
    │   ├── data/repositories/vault_repository.dart
    │   └── presentation/
    │       ├── providers/vault_providers.dart
    │       ├── pages/vault_lock_screen.dart
    │       ├── pages/vault_setup_screen.dart
    │       ├── pages/vault_screen.dart
    │       └── pages/add_edit_vault_screen.dart
    └── settings/
        └── presentation/pages/settings_screen.dart
```

---

## 🔐 Security Architecture

```
┌─────────────────────────────────────────────────────┐
│                    USER LAYER                        │
│  Master Password ──► SHA-256 hash ──► SecureStorage │
│  Biometric ───────────────────────► local_auth      │
└──────────────────────────┬──────────────────────────┘
                           │ vault unlock
┌──────────────────────────▼──────────────────────────┐
│                 ENCRYPTION LAYER                     │
│  AES-256-CBC key ──► EncryptedSharedPreferences     │
│  Plain password ──► AES encrypt ──► Hive (disk)     │
│  Decrypt ◄────────── AES decrypt ◄── Hive (read)   │
└──────────────────────────┬──────────────────────────┘
                           │ sync (encrypted only)
┌──────────────────────────▼──────────────────────────┐
│                  SUPABASE LAYER                      │
│  password_encrypted column (never plain text)        │
│  Row Level Security ── user_id isolation             │
│  Anonymous Auth ── no account required               │
└─────────────────────────────────────────────────────┘
```

**Additional security measures:**
- Clipboard cleared 30 seconds after password copy
- Password field auto-hides after 10 seconds
- Vault auto-locks after 5 minutes of inactivity
- `allowBackup="false"` in AndroidManifest — prevents ADB backup extraction
- HTTPS-only enforced via `network_security_config.xml`
- ProGuard/R8 code shrinking & obfuscation on release builds

---

## 🎨 Design System

```dart
// Background layers
AppColors.background       // #0F0F0F — base canvas
AppColors.surface          // #1A1A1A — cards, nav bar
AppColors.surfaceElevated  // #242424 — dialogs, elevated surfaces

// Glass effect
AppColors.glassBase        // rgba(255,255,255,0.08)
AppColors.glassBorder      // rgba(255,255,255,0.10)

// Accent
AppColors.accent           // #3B82F6 — primary interactive
AppColors.vault            // #8B5CF6 — vault purple

// Typography: Sora (Google Fonts)
// Corners: 8 / 12 / 16 / 20 / 100 radius scale
// Motion: flutter_animate — 200-400ms, easeInOut / easeOutBack
```

---

## 🧪 Testing

```bash
# Unit tests
flutter test

# Integration tests (device connected)
flutter test integration_test/

# Coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## 📋 Roadmap

- [ ] Import / Export (CSV, JSON)
- [ ] Tag system (multi-group membership)
- [ ] Link health checker (detect dead URLs)
- [ ] QR code share for links
- [ ] iOS support (Swift Keychain for secure storage)
- [ ] Widget for home screen shortcuts (Android 12+)
- [ ] Passkey / FIDO2 vault unlock

---

## 📄 License

MIT © 2024 LinkVault

---

> Built with Flutter 💙 — No ads, no trackers, your data stays yours.
