import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants/app_colors.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/risk_assessment_provider.dart';
import 'providers/questionnaire_provider.dart';
import 'providers/company_history_provider.dart';
import 'providers/ai_report_provider.dart';
import 'services/auth_service.dart';
import 'services/ai_service.dart';
import 'services/storage_service.dart';
import 'services/otp_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/create_questionnaire_screen.dart';
import 'screens/questionnaire_list_screen.dart';
import 'screens/answer_questionnaire_screen.dart';
import 'screens/company_history_screen.dart';
import 'screens/ai_report_screen.dart';
import 'screens/approval_screen.dart';
import 'screens/sub_department_management_screen.dart';
import 'screens/profile_edit_screen.dart';
import 'widgets/authorized_route.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final authService = AuthService();
  final aiService = AIService();
  final storageService = StorageService();
  final otpService = OTPService();

  await GoogleFonts.pendingFonts([
    GoogleFonts.inter(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => AuthProvider(authService, otpService)),
        ChangeNotifierProxyProvider<AuthProvider, CompanyHistoryProvider>(
          create: (_) => CompanyHistoryProvider(),
          update: (_, auth, history) {
            history ??= CompanyHistoryProvider();
            history.setAccessToken(auth.accessToken);
            return history;
          },
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
            create: (_) => RiskAssessmentProvider(aiService)),
        ChangeNotifierProvider(create: (_) => QuestionnaireProvider()),
        ChangeNotifierProvider(
            create: (_) => AIReportProvider(aiService, storageService)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.themeMode == ThemeMode.dark;

        return MaterialApp(
          title: 'CyGuardian',
          debugShowCheckedModeBanner: false,
          locale: const Locale('en', 'US'),
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: AppColors.scaffoldBackgroundLight,
            textTheme: GoogleFonts.interTextTheme().copyWith(
              displayLarge: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              displayMedium: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              displaySmall: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              headlineLarge: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              headlineMedium: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              headlineSmall: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              titleLarge: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              titleMedium: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              titleSmall: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              bodyLarge: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
              bodyMedium: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              bodySmall: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
              labelLarge: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              labelMedium: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              labelSmall: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: isDark
                  ? AppColors.scaffoldBackgroundDark
                  : AppColors.scaffoldBackgroundLight,
              foregroundColor: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              elevation: 0,
              centerTitle: true,
              systemOverlayStyle: isDark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              iconTheme: IconThemeData(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: AppColors.white,
                backgroundColor: AppColors.primary,
                minimumSize: const Size(120, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor:
                  isDark ? AppColors.inputFillDark : AppColors.inputFillLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.borderFocused, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: isDark
                  ? AppColors.navBarBackgroundDark
                  : AppColors.navBarBackgroundLight,
              elevation: 0,
              indicatorColor: AppColors.navBarIndicator,
              labelTextStyle: WidgetStateProperty.all(
                TextStyle(
                  color: isDark
                      ? AppColors.navBarLabelDark
                      : AppColors.navBarLabelLight,
                  fontSize: 12,
                ),
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: AppColors.cardLight,
            ),
          ),
          darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: AppColors.scaffoldBackgroundDark,
            textTheme:
                GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
              displayLarge: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              displayMedium: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              displaySmall: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              headlineLarge: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              headlineMedium: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              headlineSmall: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              titleLarge: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              titleMedium: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              titleSmall: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
              bodyLarge: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
              bodyMedium: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Colors.white70,
              ),
              bodySmall: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.white60,
              ),
              labelLarge: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              labelMedium: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
              labelSmall: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white60,
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.scaffoldBackgroundDark,
              foregroundColor: AppColors.textPrimaryDark,
              elevation: 0,
              centerTitle: true,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.textPrimaryDark,
              ),
              iconTheme: IconThemeData(
                color: AppColors.textPrimaryDark,
              ),
            ),
            cardTheme: const CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              color: AppColors.cardDark,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: AppColors.white,
                backgroundColor: AppColors.primary,
                minimumSize: const Size(120, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.inputFillDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.borderDark,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.borderDark,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.borderFocused,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 1,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
            ),
          ),
          themeMode: themeProvider.themeMode,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/dashboard': (context) => AuthorizedRoute(
                  builder: (context) => const DashboardScreen(),
                  allowedRoles: const [
                    'cto',
                    'cyberSecurityHead',
                    'subDepartmentHead'
                  ],
                ),
            '/questionnaire-list': (context) => AuthorizedRoute(
                  builder: (context) => const QuestionnaireListScreen(),
                  allowedRoles: const [
                    'cyberSecurityHead',
                    'subDepartmentHead'
                  ],
                ),
            '/create-questionnaire': (context) => AuthorizedRoute(
                  builder: (context) => const CreateQuestionnaireScreen(),
                  allowedRoles: const ['cyberSecurityHead'],
                ),
            '/answer-questionnaire': (context) => AuthorizedRoute(
                  builder: (context) =>
                      const AnswerQuestionnaireScreen(questionnaireId: ''),
                  allowedRoles: const ['subDepartmentHead'],
                ),
            '/company-history': (context) => AuthorizedRoute(
                  builder: (context) => const CompanyHistoryScreen(),
                  allowedRoles: const ['cto', 'cyberSecurityHead'],
                ),
            '/ai-report': (context) => AuthorizedRoute(
                  builder: (context) => const AIReportScreen(),
                  allowedRoles: const ['cto', 'cyberSecurityHead'],
                ),
            '/approval': (context) => AuthorizedRoute(
                  builder: (context) => const ApprovalScreen(),
                  allowedRoles: const ['cto', 'cyberSecurityHead'],
                ),
            '/sub-department-management': (context) => AuthorizedRoute(
                  builder: (context) => const SubDepartmentManagementScreen(),
                  allowedRoles: const ['cto', 'cyberSecurityHead'],
                ),
            '/profile-edit': (context) => AuthorizedRoute(
                  builder: (context) => const ProfileEditScreen(),
                  allowedRoles: const [
                    'cto',
                    'cyberSecurityHead',
                    'subDepartmentHead'
                  ],
                ),
          },
        );
      },
    );
  }
}
