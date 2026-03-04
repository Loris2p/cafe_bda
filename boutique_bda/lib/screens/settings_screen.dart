import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSavedName();
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
                      subtitle: const Text('Créer un compte pour un nouveau membre'),
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
                activeColor: Colors.orange,
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
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Changer le mot de passe'),
                    subtitle: const Text('Modifier votre mot de passe de connexion'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showChangePasswordDialog(context),
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
            const Center(
              child: Text('Version 2.0.0 (Firebase Native)', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
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
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminProvider>().setAdmin(false);
              context.read<AuthService>().signOut();
              Navigator.pop(context); // Quitter les paramètres
            },
            child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    bool isLoading = false;
    String? error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text('Changer le mot de passe', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  prefixIcon: Icon(Icons.lock_reset),
                ),
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
                  final password = passwordController.text.trim();
                  final confirm = confirmController.text.trim();

                  if (password.isEmpty) {
                    setState(() => error = 'Le mot de passe ne peut pas être vide');
                    return;
                  }
                  if (password != confirm) {
                    setState(() => error = 'Les mots de passe ne correspondent pas');
                    return;
                  }
                  if (password.length < 6) {
                    setState(() => error = '6 caractères minimum');
                    return;
                  }

                  setState(() {
                    isLoading = true;
                    error = null;
                  });

                  try {
                    await ctx.read<AuthService>().updatePassword(password);
                    if (!context.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mot de passe mis à jour !'), backgroundColor: Colors.green),
                    );
                  } catch (e) {
                    setState(() {
                      isLoading = false;
                      error = 'Erreur : $e';
                    });
                  }
                },
                child: const Text('MODIFIER'),
              ),
          ],
        ),
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
              const SizedBox(height: 8),
              const Text(
                'Un mot de passe aléatoire sera généré. L\'utilisateur devra le changer à sa première connexion.',
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
                  final password = generateRandomPassword();
                  
                  try {
                    await ctx.read<AuthService>().registerUser(email, name, password);
                    if (!context.mounted) return;
                    Navigator.pop(ctx);
                    _showSuccessDialog(context, email, password, name);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
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

  void _showSuccessDialog(BuildContext context, String email, String password, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Utilisateur inscrit !'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Veuillez transmettre ces identifiants à l\'utilisateur :'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _copyableRow('Email', email),
                  const Divider(),
                  _copyableRow('Mot de passe', password),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _sendEmail(email, password, name),
            icon: const Icon(Icons.email_outlined),
            label: const Text('ENVOYER PAR EMAIL'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
        ],
      ),
    );
  }

  Future<void> _sendEmail(String email, String password, String name) async {
    final subject = Uri.encodeComponent('Bienvenue sur l\'app Boutique BDA !');
    final body = Uri.encodeComponent(
      'Bonjour $name,\n\n'
      'Ton compte pour l\'application Boutique BDA a été créé.\n\n'
      'Voici tes identifiants :\n'
      'Email : $email\n'
      'Mot de passe temporaire : $password\n\n'
      'Note : Tu devras modifier ce mot de passe lors de ta première connexion.\n\n'
      'Tu peux télécharger la dernière version de l\'application ici :\n'
      'https://github.com/Loris2p/cafe_bda/releases\n\n'
      'L\'équipe BDA'
    );
    
    final url = Uri.parse('mailto:$email?subject=$subject&body=$body');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir votre application de mail')),
        );
      }
    }
  }

  Widget _copyableRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 20),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label copié !'), duration: const Duration(seconds: 1)),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
    );
  }
}
