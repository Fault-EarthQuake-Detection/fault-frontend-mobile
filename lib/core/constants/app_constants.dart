// lib/core/constants/app_constants.dart

import 'dart:io';

import 'package:flutter/foundation.dart';

class AppConstants {
  static const String supabaseUrl = "https://rnryyluyzknrckfaaxqr.supabase.co";
  static const String supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJucnl5bHV5emtucmNrZmFheHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE2MTY5OTEsImV4cCI6MjA3NzE5Mjk5MX0.gDcPUJHXB8VnW_LeXgtV5om2S6fKab99Fu76v5MyLtM";

  static String get _baseUrl {
    if (kIsWeb) {
      return "http://localhost:3000";
    } else if (Platform.isAndroid) {
      return "http://192.168.100.9:3000";
    } else {
      return "http://localhost:3000";
    }
  }

  static String get apiBaseUrl => "$_baseUrl/api";
  static String get authBaseUrl => "$_baseUrl/auth";

  static const String aiApiUrl = "https://fikalalif-fault-detection-api.hf.space";
}