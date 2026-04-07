// lib/services/supabase_service.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wrapper around Supabase client with table name constants.
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // Table names
  static const linksTable = 'links';
  static const groupsTable = 'groups';
  static const vaultTable = 'vault_entries';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }

  static User? get currentUser => client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;
  static String? get userId => currentUser?.id;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  static Future<AuthResponse> signInAnonymously() async {
    return await client.auth.signInAnonymously();
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }
}

/// Supabase table schemas (SQL — run in Supabase dashboard)
/// 
/// -- Links table
/// CREATE TABLE links (
///   id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
///   user_id UUID REFERENCES auth.users NOT NULL,
///   title TEXT NOT NULL,
///   url TEXT NOT NULL,
///   description TEXT DEFAULT '',
///   group_id UUID REFERENCES groups(id),
///   is_favorite BOOLEAN DEFAULT false,
///   click_count INT DEFAULT 0,
///   last_opened_at TIMESTAMPTZ,
///   created_at TIMESTAMPTZ DEFAULT NOW(),
///   updated_at TIMESTAMPTZ DEFAULT NOW()
/// );
/// ALTER TABLE links ENABLE ROW LEVEL SECURITY;
/// CREATE POLICY "Users can manage own links" ON links
///   FOR ALL USING (auth.uid() = user_id);
///
/// -- Groups table
/// CREATE TABLE groups (
///   id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
///   user_id UUID REFERENCES auth.users NOT NULL,
///   name TEXT NOT NULL,
///   icon TEXT DEFAULT 'folder',
///   color TEXT DEFAULT '#3B82F6',
///   created_at TIMESTAMPTZ DEFAULT NOW()
/// );
/// ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
/// CREATE POLICY "Users can manage own groups" ON groups
///   FOR ALL USING (auth.uid() = user_id);
///
/// -- Vault entries table
/// CREATE TABLE vault_entries (
///   id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
///   user_id UUID REFERENCES auth.users NOT NULL,
///   app_name TEXT NOT NULL,
///   username TEXT NOT NULL,
///   password_encrypted TEXT NOT NULL,
///   notes TEXT DEFAULT '',
///   created_at TIMESTAMPTZ DEFAULT NOW(),
///   updated_at TIMESTAMPTZ DEFAULT NOW()
/// );
/// ALTER TABLE vault_entries ENABLE ROW LEVEL SECURITY;
/// CREATE POLICY "Users can manage own vault" ON vault_entries
///   FOR ALL USING (auth.uid() = user_id);
