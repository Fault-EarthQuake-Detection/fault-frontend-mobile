// lib/core/constants/app_constants.dart

import 'package:flutter/foundation.dart';

class AppConstants {
  static const String supabaseUrl = "https://rnryyluyzknrckfaaxqr.supabase.co";
  static const String supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJucnl5bHV5emtucmNrZmFheHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE2MTY5OTEsImV4cCI6MjA3NzE5Mjk5MX0.gDcPUJHXB8VnW_LeXgtV5om2S6fKab99Fu76v5MyLtM";

  static const String _laptopIp = "192.168.100.9";

  static String get _baseUrl {
    if (kIsWeb) {
      return "http://localhost:3000";
    } else {
      return "http://$_laptopIp:3000";
    }
  }

  static String get apiBaseUrl => "$_baseUrl/api";
  static String get authBaseUrl => "$_baseUrl/auth";

  static const String aiApiUrl = "https://fikalalif-fault-detection-api.hf.space";
}