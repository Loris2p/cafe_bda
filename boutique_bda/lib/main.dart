import 'dart:io' show Platform;
import 'package:firedart/firedart.dart' as fd;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/prefs_token_store.dart';
import 'screens/main_screen.dart';
import 'screens/change_password_screen.dart';
import 'models/app_user.dart';
import 'core/app_theme.dart';

class AdminProvider with ChangeNotifier {
  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  // Liste des emails autorisés
  static const List<String> _allowedAdmins = [
    'loris.lahon@gmail.com',
    'bdapaucytech@gmail.com',
  ];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isAdmin = prefs.getBool('is_admin_mode') ?? false;
    notifyListeners();
  }

  void setAdmin(bool value, {String? userEmail, BuildContext? context}) async {
    if (value && userEmail != null && context != null) {
      if (_allowedAdmins.contains(userEmail)) {
        _isAdmin = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_admin_mode', true);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mode Administrateur activé'), backgroundColor: Colors.orange),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Accès refusé : vous n\'êtes pas administrateur'), backgroundColor: Colors.red),
          );
        }
        _isAdmin = false;
      }
    } else {
      _isAdmin = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_admin_mode', value);
    }
    notifyListeners();
  }
}

class TabProvider with ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  void setTab(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final adminProvider = AdminProvider();
  await adminProvider.init();

  if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
    final prefs = await SharedPreferences.getInstance();
    fd.FirebaseAuth.initialize(
      DefaultFirebaseOptions.windows.apiKey, 
      PrefsTokenStore(prefs)
    );
    fd.Firestore.initialize(DefaultFirebaseOptions.windows.projectId);
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: adminProvider),
        ChangeNotifierProvider(create: (_) => TabProvider()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirebaseService>(create: (_) => FirebaseService()),
        StreamProvider<AppUser?>(
          create: (context) => context.read<AuthService>().user,
          initialData: null,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AdminProvider>().isAdmin;

    return MaterialApp(
      title: 'Boutique BDA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(isAdmin: isAdmin),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return VersionCheckWrapper(
      child: _buildAuthContent(context),
    );
  }

  Widget _buildAuthContent(BuildContext context) {
    final user = context.watch<AppUser?>();
    
    if (user == null) {
      return const LoginScreen();
    }
    
    if (user.mustChangePassword) {
      return const ChangePasswordScreen();
    }

    return const MainScreen();
  }
}

class VersionCheckWrapper extends StatefulWidget {
  final Widget child;
  const VersionCheckWrapper({super.key, required this.child});

  @override
  State<VersionCheckWrapper> createState() => _VersionCheckWrapperState();
}

class _VersionCheckWrapperState extends State<VersionCheckWrapper> {
  bool _isChecking = true;
  bool _needsUpdate = false;
  String _latestVersion = '';

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      final latestVersion = await context.read<FirebaseService>().getLatestVersion();
      
      if (latestVersion != null && _isVersionLower(currentVersion, latestVersion)) {
        setState(() {
          _needsUpdate = true;
          _latestVersion = latestVersion;
          _isChecking = false;
        });
      } else {
        setState(() {
          _isChecking = false;
        });
      }
    } catch (e) {
      print('Version check error: $e');
      setState(() => _isChecking = false);
    }
  }

  bool _isVersionLower(String current, String latest) {
    try {
      final v1 = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final v2 = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      
      for (var i = 0; i < 3; i++) {
        final n1 = v1.length > i ? v1[i] : 0;
        final n2 = v2.length > i ? v2[i] : 0;
        if (n1 < n2) return true;
        if (n1 > n2) return false;
      }
    } catch (e) {
      print('Error comparing versions: $e');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_needsUpdate) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade900, Colors.red.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.system_update_alt, size: 80, color: Colors.white),
              const SizedBox(height: 24),
              Text(
                'Mise à jour requise',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Une nouvelle version ($_latestVersion) est disponible. Vous devez mettre à jour l\'application pour continuer.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () => launchUrl(Uri.parse('https://github.com/Loris2p/cafe_bda/releases')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade900,
                  minimumSize: const Size(double.infinity, 60),
                ),
                icon: const Icon(Icons.download),
                label: const Text('TÉLÉCHARGER LA DERNIÈRE VERSION'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                children: [
                  // Logo et Titre
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset('assets/icon/logoBDA_4_complet.png', height: 80),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Boutique BDA',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Formulaire
                  Card(
                    elevation: 20,
                    shadowColor: Colors.black.withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Connexion',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextField(
                            controller: _emailController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _passwordController,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _handleLogin(),
                            decoration: const InputDecoration(
                              labelText: 'Mot de passe',
                              prefixIcon: Icon(Icons.lock_outline_rounded),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 40),
                          if (_isLoading)
                            const CircularProgressIndicator()
                          else
                            ElevatedButton(
                              onPressed: _handleLogin,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 60),
                                elevation: 0,
                              ),
                              child: const Text('SE CONNECTER'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await context.read<AuthService>().signInWithEmail(email, password);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
