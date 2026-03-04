import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../main.dart';
import '../models/app_user.dart';

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
    final theme = Theme.of(context);

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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
    );
  }
}
