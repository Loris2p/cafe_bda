import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../main.dart';
import '../models/app_user.dart';
import '../models/feedback_item.dart';
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
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.fact_check_outlined, color: Colors.teal),
                      title: const Text('Suivi des retours envoyés'),
                      subtitle: const Text('Voir les idées/bugs et le statut GitHub'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showFeedbackHistorySheet(context),
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

            _buildSectionTitle('Aide & Retours'),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lightbulb_outline, color: Colors.purple),
                ),
                title: const Text('Proposer une idée / Signaler un bug'),
                subtitle: const Text('Synchronisé automatiquement avec le GitHub du projet'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showSubmitFeedbackDialog(context, user),
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
      final authService = context.read<AuthService>();
      await authService.sendPasswordResetEmail(email);
      if (!context.mounted) return;
      showCustomSnackBar(
        context, 
        message: 'Lien de réinitialisation envoyé à $email', 
        backgroundColor: Colors.green,
        icon: Icons.mark_email_read_outlined,
      );
    } catch (e) {
      if (!context.mounted) return;
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
                    _showSuccessDialog(context, email, name, tempPassword);
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

  void _showSuccessDialog(BuildContext context, String email, String name, String password) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Utilisateur inscrit !'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Le compte de $name a été créé.'),
            const SizedBox(height: 16),
            const Text('Veuillez envoyer ses accès manuellement :'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email : $email', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Mot de passe : $password', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
          ElevatedButton.icon(
            onPressed: () async {
              final String subject = Uri.encodeComponent("Tes accès - Boutique BDA");
              final String body = Uri.encodeComponent(
                "Salut $name !\n\n"
                "Voici tes identifiants pour te connecter à l'application Boutique BDA :\n"
                "- Email : $email\n"
                "- Mot de passe : $password\n\n"
                "Tu pourras changer ton mot de passe lors de ta première connexion.\n\n"
                "Tu peux te connecter directement à l'application web ici : https://boutique-bda.web.app\n\n"
                "À bientôt !"
              );
              final Uri mailUri = Uri.parse("mailto:$email?subject=$subject&body=$body");
              
              if (await canLaunchUrl(mailUri)) {
                await launchUrl(mailUri);
              }
            },
            icon: const Icon(Icons.send_rounded),
            label: const Text('ENVOYER LES ACCÈS'),
          ),
        ],
      ),
    );
  }

  String _detectPlatformLabel() {
    final osName = defaultTargetPlatform.name;
    return kIsWeb ? 'Web ($osName)' : osName;
  }

  void _showSubmitFeedbackDialog(BuildContext context, AppUser? user) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    FeedbackType selectedType = FeedbackType.idea;
    bool isSubmitting = false;

    final authorName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : (user?.displayName?.isNotEmpty == true
            ? user!.displayName!
            : (user?.email?.split('@').first ?? 'Membre BDA'));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Row(
            children: [
              Icon(
                selectedType == FeedbackType.idea ? Icons.lightbulb_outline : Icons.bug_report_outlined,
                color: selectedType == FeedbackType.idea ? Colors.purple : Colors.redAccent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Votre retour',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<FeedbackType>(
                    segments: const [
                      ButtonSegment(
                        value: FeedbackType.idea,
                        label: Text('Idée'),
                        icon: Icon(Icons.lightbulb_outline),
                      ),
                      ButtonSegment(
                        value: FeedbackType.bug,
                        label: Text('Bug'),
                        icon: Icon(Icons.bug_report_outlined),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (selection) {
                      setModalState(() => selectedType = selection.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: selectedType == FeedbackType.idea
                          ? 'Titre de l\'idée'
                          : 'Résumé du problème',
                      hintText: selectedType == FeedbackType.idea
                          ? 'Ex: Ajouter un filtre par catégorie dans les stats'
                          : 'Ex: Le bouton de rechargement ne répond pas',
                      prefixIcon: const Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Description détaillée',
                      hintText: selectedType == FeedbackType.idea
                          ? 'Explique comment cette amélioration aiderait au quotidien...'
                          : 'Explique comment reproduire le bug et ce qui s\'est passé...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Auteur : $authorName • v$_appVersion (${_detectPlatformLabel()})\nUne GitHub Issue sera créée automatiquement.',
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            if (isSubmitting)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              ElevatedButton.icon(
                onPressed: () async {
                  final title = titleController.text.trim();
                  final desc = descController.text.trim();
                  if (title.isEmpty || desc.isEmpty) {
                    showCustomSnackBar(
                      this.context,
                      message: 'Merci de remplir le titre et la description.',
                      backgroundColor: Colors.orange,
                      icon: Icons.warning_amber_rounded,
                    );
                    return;
                  }

                  setModalState(() => isSubmitting = true);
                  try {
                    final feedback = FeedbackItem(
                      id: '',
                      type: selectedType,
                      title: title,
                      description: desc,
                      authorName: authorName,
                      authorEmail: user?.email,
                      appVersion: _appVersion,
                      platform: _detectPlatformLabel(),
                      createdAt: DateTime.now(),
                    );
                    await this.context.read<FirebaseService>().addFeedback(feedback);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                    if (!mounted) return;
                    showCustomSnackBar(
                      this.context,
                      message: 'Retour enregistré ! Il sera synchronisé sur GitHub.',
                      backgroundColor: Colors.green,
                      icon: Icons.check_circle_outline,
                    );
                  } catch (e) {
                    if (!mounted) return;
                    showCustomSnackBar(
                      this.context,
                      message: 'Erreur lors de l\'envoi : $e',
                      backgroundColor: Colors.red,
                      icon: Icons.error_outline,
                    );
                    setModalState(() => isSubmitting = false);
                  }
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('ENVOYER'),
              ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackHistorySheet(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.fact_check_outlined, color: Colors.teal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Retours & Idées soumis',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<FeedbackItem>>(
                  stream: firebaseService.getFeedbacks(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return const Center(
                        child: Text(
                          'Aucun retour envoyé pour le moment.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isIdea = item.type == FeedbackType.idea;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          leading: CircleAvatar(
                            backgroundColor: (isIdea ? Colors.purple : Colors.redAccent).withValues(alpha: 0.12),
                            child: Icon(
                              isIdea ? Icons.lightbulb_outline : Icons.bug_report_outlined,
                              color: isIdea ? Colors.purple : Colors.redAccent,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                item.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Par ${item.authorName} • ${dateFormat.format(item.createdAt)}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: item.syncedToGithub
                                          ? Colors.green.withValues(alpha: 0.12)
                                          : Colors.orange.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      item.syncedToGithub
                                          ? 'GitHub #${item.githubIssueNumber ?? "OK"}'
                                          : 'En attente GitHub',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: item.syncedToGithub ? Colors.green.shade700 : Colors.orange.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: item.githubIssueUrl != null
                              ? IconButton(
                                  tooltip: 'Ouvrir sur GitHub',
                                  icon: const Icon(Icons.open_in_new, size: 20),
                                  onPressed: () async {
                                    final uri = Uri.parse(item.githubIssueUrl!);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                )
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
