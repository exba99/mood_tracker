// ============================================
// APPLICATION PRINCIPALE : MOOD TRACKER
// ============================================
// Cette application permet aux apprenants d'enregistrer leur humeur quotidienne

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/mood.dart';
import 'services/mood_service.dart';

// ============================================
// POINT D'ENTRÉE DE L'APPLICATION
// ============================================
void main() {
  runApp(const MyApp());
}

// ============================================
// WIDGET PRINCIPAL DE L'APPLICATION
// ============================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood Tracker',
      debugShowCheckedModeBanner: false, // Retire le bandeau "DEBUG"
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MoodBoardPage(),
    );
  }
}

// ============================================
// PAGE PRINCIPALE : MOOD BOARD
// ============================================
// StatefulWidget car la page a un état qui change (liste des humeurs, formulaire, etc.)
class MoodBoardPage extends StatefulWidget {
  const MoodBoardPage({super.key});

  @override
  State<MoodBoardPage> createState() => _MoodBoardPageState();
}

class _MoodBoardPageState extends State<MoodBoardPage> {
  // ========================================
  // VARIABLES D'ÉTAT
  // ========================================

  // Service pour communiquer avec l'API
  final MoodService _moodService = MoodService();

  // Clé pour valider le formulaire
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs pour les champs de texte
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _commentaireController = TextEditingController();

  // Contrôleur pour le scroll automatique
  final _scrollController = ScrollController();

  // État du formulaire
  String _selectedMood = '😊'; // Humeur sélectionnée
  List<Mood> _moods = []; // Liste de toutes les humeurs
  bool _isLoading = false; // Chargement en cours ?
  bool _isSubmitting = false; // Soumission en cours ?
  Mood? _editingMood; // Humeur en cours de modification (null si création)

  // Options d'humeur disponibles (emoji => texte)
  final Map<String, String> _moodOptions = {
    '😊': 'Heureux',
    '😢': 'Triste',
    '😡': 'En colère',
    '🤔': 'Neutre',
    '💪': 'Motivé',
    '😴': 'Fatigué',
  };

  // ========================================
  // CYCLE DE VIE DU WIDGET
  // ========================================

  @override
  void initState() {
    super.initState();
    _loadMoods(); // Charge les humeurs au démarrage
  }

  @override
  void dispose() {
    // Nettoie les contrôleurs pour libérer la mémoire
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _commentaireController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ========================================
  // MÉTHODES DE GESTION DES DONNÉES
  // ========================================

  /// Charge toutes les humeurs depuis l'API
  Future<void> _loadMoods() async {
    setState(() => _isLoading = true);

    try {
      final moods = await _moodService.getMoods();
      setState(() {
        _moods = moods;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('Erreur lors du chargement des humeurs: $e');
    }
  }

  /// Soumet le formulaire (création ou modification)
  Future<void> _submitMood() async {
    // Vérifie que le formulaire est valide
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Crée l'objet Mood avec les données du formulaire
      final moodData = Mood(
        nom: _nomController.text,
        prenom: _prenomController.text,
        email: _emailController.text,
        mood: _selectedMood,
        commentaire: _commentaireController.text,
        date:
            _editingMood?.date ??
            DateTime.now(), // Garde la date si modification
      );

      // Mode modification ou création ?
      if (_editingMood != null) {
        // MODIFICATION : appelle l'API PUT
        await _moodService.updateMood(
          _editingMood!.email,
          _editingMood!.date,
          moodData,
        );
        _showSuccessMessage('Humeur modifiée avec succès!');
      } else {
        // CRÉATION : appelle l'API POST
        await _moodService.createMood(moodData);
        _showSuccessMessage('Humeur ajoutée avec succès!');
      }

      // Réinitialise le formulaire
      _clearForm();

      // Recharge la liste des humeurs
      await _loadMoods();
    } catch (e) {
      _showErrorMessage(
        _editingMood != null
            ? 'Erreur lors de la modification: $e'
            : 'Erreur lors de l\'ajout: $e',
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  /// Supprime une humeur après confirmation
  Future<void> _deleteMood(Mood mood) async {
    // Demande confirmation à l'utilisateur
    final confirm = await _showDeleteConfirmation();
    if (confirm != true) return;

    try {
      await _moodService.deleteMood(mood.email, mood.date);
      await _loadMoods();
      _showSuccessMessage('Humeur supprimée avec succès!');
    } catch (e) {
      _showErrorMessage('Erreur lors de la suppression: $e');
    }
  }

  // ========================================
  // MÉTHODES D'INTERFACE UTILISATEUR
  // ========================================

  /// Active le mode édition et remplit le formulaire
  void _loadEditMode(Mood mood) {
    // Remplit les champs avec les données de l'humeur
    _nomController.text = mood.nom;
    _prenomController.text = mood.prenom;
    _emailController.text = mood.email;
    _commentaireController.text = mood.commentaire;

    setState(() {
      _selectedMood = mood.mood;
      _editingMood = mood;
    });

    // Scroll automatique vers le formulaire
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        0, // Position en haut
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  /// Annule l'édition et réinitialise le formulaire
  void _clearForm() {
    _formKey.currentState!.reset();
    _nomController.clear();
    _prenomController.clear();
    _emailController.clear();
    _commentaireController.clear();
    setState(() {
      _selectedMood = '😊';
      _editingMood = null;
    });
  }

  /// Affiche une boîte de dialogue de confirmation de suppression
  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette humeur?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Affiche un message de succès (barre verte)
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  /// Affiche un message d'erreur (barre rouge)
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ========================================
  // CONSTRUCTION DE L'INTERFACE
  // ========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Board des apprenants'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: GestureDetector(
        // Ferme le clavier quand on tape en dehors des champs
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormCard(), // Formulaire d'ajout/modification
              const SizedBox(height: 24),
              _buildMoodsList(), // Liste des humeurs
            ],
          ),
        ),
      ),
    );
  }

  /// Construit la carte contenant le formulaire
  Widget _buildFormCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre du formulaire (change selon le mode)
              Text(
                _editingMood != null
                    ? 'Modifier une humeur'
                    : 'Ajouter une humeur',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Champ Nom
              _buildTextField(
                controller: _nomController,
                label: 'Nom',
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Le nom est requis' : null,
              ),
              const SizedBox(height: 12),

              // Champ Prénom
              _buildTextField(
                controller: _prenomController,
                label: 'Prénom',
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Le prénom est requis' : null,
              ),
              const SizedBox(height: 12),

              // Champ Email
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'L\'email est requis';
                  if (!value!.contains('@')) return 'Email invalide';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Sélecteur d'humeur
              _buildMoodDropdown(),
              const SizedBox(height: 12),

              // Champ Commentaire
              _buildTextField(
                controller: _commentaireController,
                label: 'Commentaire',
                maxLines: 3,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Le commentaire est requis' : null,
              ),
              const SizedBox(height: 16),

              // Boutons d'action
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit un champ de texte avec validation
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  /// Construit le menu déroulant pour sélectionner l'humeur
  Widget _buildMoodDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedMood,
      decoration: const InputDecoration(
        labelText: 'Humeur',
        border: OutlineInputBorder(),
      ),
      items: _moodOptions.entries.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Row(
            children: [
              Text(entry.key, style: const TextStyle(fontSize: 24)), // Emoji
              const SizedBox(width: 8),
              Text(entry.value, style: const TextStyle(fontSize: 16)), // Texte
            ],
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedMood = value!),
    );
  }

  /// Construit les boutons d'action (Ajouter/Modifier et Annuler)
  Widget _buildActionButtons() {
    return Row(
      children: [
        // Bouton principal (Ajouter ou Modifier)
        Expanded(
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitMood,
            style: ElevatedButton.styleFrom(
              backgroundColor: _editingMood != null
                  ? Colors.orange
                  : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(_editingMood != null ? 'Modifier' : 'Ajouter'),
          ),
        ),

        // Bouton Annuler (visible uniquement en mode édition)
        if (_editingMood != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : _clearForm,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Annuler'),
            ),
          ),
        ],
      ],
    );
  }

  /// Construit la section de liste des humeurs
  Widget _buildMoodsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Liste des humeurs',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Affiche selon l'état
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_moods.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text('Aucune humeur pour le moment')),
            ),
          )
        else
          // Liste des cartes d'humeur
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _moods.length,
            itemBuilder: (context, index) {
              final mood = _moods[index];
              return MoodCard(
                mood: mood,
                moodLabel: _moodOptions[mood.mood] ?? '',
                onEdit: () => _loadEditMode(mood),
                onDelete: () => _deleteMood(mood),
              );
            },
          ),
      ],
    );
  }
}

// ============================================
// WIDGET : CARTE D'HUMEUR
// ============================================
// Affiche une humeur individuelle sous forme de carte

class MoodCard extends StatelessWidget {
  final Mood mood; // Les données de l'humeur
  final String moodLabel; // Le label textuel de l'humeur
  final VoidCallback onEdit; // Fonction appelée lors du clic sur Modifier
  final VoidCallback onDelete; // Fonction appelée lors du clic sur Supprimer

  const MoodCard({
    super.key,
    required this.mood,
    required this.moodLabel,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Format pour afficher la date
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne 1 : Nom + Emoji et Boutons d'action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Informations de l'apprenant
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom complet et emoji
                      Row(
                        children: [
                          Text(
                            '${mood.nom} ${mood.prenom}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(mood.mood, style: const TextStyle(fontSize: 24)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Email
                      Text(
                        mood.email,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Boutons d'action
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: onEdit,
                      tooltip: 'Modifier',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                      tooltip: 'Supprimer',
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Ligne 2 : Commentaire
            Text(mood.commentaire, style: const TextStyle(fontSize: 14)),

            const SizedBox(height: 8),

            // Ligne 3 : Date
            Text(
              dateFormat.format(mood.date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
