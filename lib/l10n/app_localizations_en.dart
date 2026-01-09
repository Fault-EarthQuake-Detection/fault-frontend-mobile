// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get themeTitle => 'Dark Mode';

  @override
  String get themeSubtitle => 'Enable dark appearance';

  @override
  String get langTitle => 'Language';

  @override
  String get langSubtitle => 'Select application language';

  @override
  String get profileTitle => 'User Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String get aboutApp => 'About App';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmTitle => 'Confirm Logout';

  @override
  String get logoutConfirmMsg => 'Are you sure you want to log out?';

  @override
  String get cancel => 'Cancel';

  @override
  String get yesLogout => 'Yes, Logout';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get username => 'Username';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get orLoginWith => 'Or login with';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get invalidEmail => 'Invalid email format';

  @override
  String get passwordLength => 'Minimum 8 characters';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get appTagline =>
      'Interactive Geological Education\n& Fault Line Validation';

  @override
  String get welcomeTitle => 'GeoValid';

  @override
  String get changePhoto => 'Tap camera icon to change photo';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get writeFeedback => 'Write your feedback or complaints...';

  @override
  String get oldPassword => 'Old Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get repeatPassword => 'Repeat Password';

  @override
  String get feedbackSent => 'Feedback sent!';

  @override
  String get feedbackDesc =>
      'We appreciate your feedback for the development of this application.';

  @override
  String get aboutDesc =>
      'GeoValid is an interactive geological education and validation application designed to help users identify fault lines using AI technology.';

  @override
  String get latestInfo => 'Latest Updates';

  @override
  String get citizenReport => 'Citizen Report';

  @override
  String get bmkgOfficial => 'BMKG Official';

  @override
  String get you => 'You';

  @override
  String get magnitude => 'Magnitude';

  @override
  String get depth => 'Depth';

  @override
  String get potential => 'Potential';

  @override
  String get time => 'Time';

  @override
  String get date => 'Date';

  @override
  String get coordinates => 'Coordinates';

  @override
  String get felt => 'Felt (MMI)';

  @override
  String get analysisDetail => 'Analysis Detail';

  @override
  String get viewOnMap => 'View on Map';

  @override
  String get bmkgDisclaimer =>
      'Data sourced officially from BMKG (Meteorology, Climatology, and Geophysics Agency).';

  @override
  String get tsunamiAlert => 'TSUNAMI POTENTIAL';

  @override
  String get safe => 'Safe';

  @override
  String get faultPattern => 'Fault Pattern';

  @override
  String get aiAnalysis => 'AI Analysis';

  @override
  String earthquakeInfo(String magnitude, String region) {
    return 'Earthquake Mag $magnitude in $region';
  }

  @override
  String get detectionTitle => 'Fault Detection';

  @override
  String get detectionSource => 'GeoValid User';

  @override
  String get faultType => 'Fault Type';

  @override
  String get analysisResult => 'Analysis Result';

  @override
  String get finalStatus => 'Final Status';

  @override
  String get visualAnalysis => 'Visual Analysis (AI)';

  @override
  String get geoAnalysis => 'Geospatial Analysis';

  @override
  String get zone => 'Zone';

  @override
  String get nearestFault => 'Nearest Fault';

  @override
  String get distance => 'Distance';

  @override
  String get doneReturn => 'Done & Return';

  @override
  String get showingArchive => 'Showing archived detection history.';

  @override
  String get dataSaved => 'Analysis result has been saved automatically.';

  @override
  String get noDescription => 'No description available.';

  @override
  String get unidentified => 'Unidentified';

  @override
  String get selectLocation => 'Select Location';

  @override
  String get searchLocation => 'Search location...';

  @override
  String get useThisLocation => 'Use This Location';

  @override
  String get searchingGPS => 'Searching GPS...';

  @override
  String get cameraPermission => 'Camera Permission Required';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get retakePhoto => 'Retake Photo';

  @override
  String get noImage => 'Image lost. Please retake photo.';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get uploadFailed => 'Upload failed';

  @override
  String get dragMap => 'Drag map to adjust location';

  @override
  String get mapDistribution => 'Fault Distribution Map';

  @override
  String get searchPlace => 'Search place...';

  @override
  String get verified => 'Verified';

  @override
  String get detectionDetail => 'Detection Detail';

  @override
  String get status => 'Status';

  @override
  String get type => 'Type';

  @override
  String get validatedAt => 'Validated at';

  @override
  String get menu => 'Menu';

  @override
  String get searchHistory => 'Search my history...';

  @override
  String get myDetectionHistory => 'MY DETECTION HISTORY';

  @override
  String get notFound => 'Not found';

  @override
  String get unknown => 'Unknown';

  @override
  String get navHome => 'Home';

  @override
  String get navDetection => 'Detection';

  @override
  String get navMap => 'Map';

  @override
  String get navProfile => 'Profile';

  @override
  String get imageNotAvailable => 'Image not available';
}
