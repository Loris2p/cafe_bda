import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/auth_service.dart';
import '../main.dart';
import '../models/app_user.dart';
import '../core/utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  bool _isSaving = false;
  String _appVersion = 'Chargement...';

  @override
  void initState() {
    super.initState();
    _loadSavedName();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  Future<void> _loadSavedName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('responsible_name') ?? '';
    });
  }

  Future<void> _saveName() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('responsible_name', _nameController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nom du responsable enregistré !'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AdminProvider>().isAdmin;
    final user = context.watch<AppUser?>();

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Mon Profil'),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du responsable',
                        hintText: 'Ex: Loris',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveName,
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('ENREGISTRER'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            if (isAdmin) ...[
              _buildSectionTitle('Administration'),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_add_alt_1_outlined, color: Colors.blue),
                      title: const Text('Inscrire un utilisateur'),
                      subtitle: const Text('Créer un compte pour un nouveau étudiant'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showRegisterUserDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            _buildSectionTitle('Sécurité'),
            const SizedBox(height: 16),
            Card(
              child: SwitchListTile(
                title: Text('Mode Administrateur', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                subtitle: const Text('Accès aux prix et statistiques'),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isAdmin ? Colors.orange : Colors.grey).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.admin_panel_settings_outlined, color: isAdmin ? Colors.orange : Colors.grey),
                ),
                value: isAdmin,
                activeThumbColor: Colors.orange,
                onChanged: (val) {
                  context.read<AdminProvider>().setAdmin(
                    val, 
                    userEmail: user?.email, 
                    context: context
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            _buildSectionTitle('Compte'),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email'),
                    subtitle: Text(user?.email ?? 'Utilisateur local'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_reset),
                    title: const Text('Réinitialiser le mot de passe'),
                    subtitle: const Text('Recevoir un lien de modification par email'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _sendResetEmail(context, user?.email),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text('Déconnexion', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    onTap: () => _showLogoutDialog(context),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            Center(
              child: Text('Version $_appVersion', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendResetEmail(BuildContext context, String? email) async {
    if (email == null) return;
    try {
      await context.read<AuthService>().sendPasswordResetEmail(email);
      if (!mounted) return;
      showCustomSnackBar(
        context, 
        message: 'Lien de réinitialisation envoyé à $email', 
        backgroundColor: Colors.green,
        icon: Icons.mark_email_read_outlined,
      );
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(
        context, 
        message: 'Erreur : $e', 
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Ferme le dialogue
              
              // On récupère les instances avant de pop pour éviter les erreurs de context
              final authService = context.read<AuthService>();
              final adminProvider = context.read<AdminProvider>();
              
              // On quitte l'écran des paramètres d'abord pour revenir à l'écran principal
              Navigator.pop(context);
              
              // On réinitialise le mode admin et on déconnecte
              adminProvider.setAdmin(false);
              await authService.signOut();
            },
            child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRegisterUserDialog(BuildContext context) {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Row(
            children: [
              const Icon(Icons.person_add_alt_1_outlined, color: Colors.blue),
              const SizedBox(width: 12),
              Text('Nouvel utilisateur', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Un email sera automatiquement envoyé à l\'utilisateur pour qu\'il puisse définir son mot de passe.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              ElevatedButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  final name = nameController.text.trim();
                  if (email.isEmpty || name.isEmpty) return;

                  setState(() => isLoading = true);
                  // Mot de passe aléatoire interne (ne sera pas utilisé car réinitialisation immédiate)
                  final tempPassword = generateRandomPassword();
                  
                  try {
                    await ctx.read<AuthService>().registerUser(email, name, tempPassword);
                    if (!context.mounted) return;
                    Navigator.pop(ctx);
                    _showSuccessDialog(context, email, name);
                  } catch (e) {
                    if (!context.mounted) return;
                    showCustomSnackBar(
                      context, 
                      message: 'Erreur d\'inscription : $e', 
                      backgroundColor: Colors.red,
                      icon: Icons.error_outline,
                    );
                    setState(() => isLoading = false);
                  }
                },
                child: const Text('INSCRIRE'),
              ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String email, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Utilisateur inscrit !'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Le compte de $name ($email) a été créé.'),
            const SizedBox(height: 16),
            const Text('Un email de configuration de mot de passe lui a été envoyé automatiquement.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
    );
  }
}
