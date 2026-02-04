// ============================================
// MODÈLE DE DONNÉES : MOOD (Humeur)
// ============================================
// Ce fichier définit la structure d'une humeur dans notre application

class Mood {
  // === Propriétés de la classe ===
  // Chaque humeur contient ces informations :
  final String nom; // Nom de famille de l'apprenant
  final String prenom; // Prénom de l'apprenant
  final String email; // Email (utilisé comme identifiant unique)
  final String mood; // Emoji représentant l'humeur (😊, 😢, etc.)
  final String commentaire; // Commentaire explicatif de l'humeur
  final DateTime date; // Date et heure de l'humeur

  // === Constructeur ===
  // Permet de créer une nouvelle instance de Mood
  // Le mot-clé 'required' signifie que tous les paramètres sont obligatoires
  Mood({
    required this.nom,
    required this.prenom,
    required this.email,
    required this.mood,
    required this.commentaire,
    required this.date,
  });

  // === Méthode fromJson ===
  // Convertit des données JSON (venant de l'API) en objet Mood
  // Exemple de JSON : {"nom": "DIOP", "prenom": "Maodo", ...}
  factory Mood.fromJson(Map<String, dynamic> json) {
    return Mood(
      nom: json['nom'] ?? '', // ?? '' signifie "valeur par défaut si null"
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      mood: json['mood'] ?? '',
      commentaire: json['commentaire'] ?? '',
      date: DateTime.parse(json['date']), // Convertit le texte en DateTime
    );
  }

  // === Méthode toJson ===
  // Convertit un objet Mood en JSON (pour l'envoyer à l'API)
  // Retourne un Map qui sera automatiquement converti en JSON
  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'mood': mood,
      'commentaire': commentaire,
      'date': date
          .toIso8601String(), // Convertit DateTime en format texte standard
    };
  }
}
