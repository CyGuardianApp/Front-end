import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2A76C9),
              brightness: Brightness.light,
            ),
            textTheme: GoogleFonts.interTextTheme(),
            appBarTheme: AppBarTheme(
              backgroundColor:
                  isDark ? const Color(0xFF1A202C) : const Color(0xFF2A76C9),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              systemOverlayStyle: SystemUiOverlayStyle.light,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF2A76C9),
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
              fillColor: isDark ? const Color(0xFF2D3748) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF4A5568)
                        : const Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF4A5568)
                        : const Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF2A76C9), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: isDark ? const Color(0xFF1A202C) : Colors.white,
              elevation: 0,
              indicatorColor: const Color.fromARGB(51, 42, 118, 201),
              labelTextStyle: WidgetStateProperty.all(
                TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF2A4365),
                  fontSize: 12,
                ),
              ),
            ),
          ),
          darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2A76C9),
              brightness: Brightness.dark,
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
            scaffoldBackgroundColor: const Color(0xFF1A202C),
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
