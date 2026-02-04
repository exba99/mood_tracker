// ============================================
// SERVICE API : MOOD SERVICE
// ============================================
// Ce fichier gère toutes les communications avec l'API backend

import 'package:dio/dio.dart';
import '../models/mood.dart';

class MoodService {
  // === Configuration de l'API ===
  static const String baseUrl =
      'https://ideal-meme-x4xpxvx4xrhg5r-6671.app.github.dev/mood-application';

  // Client HTTP Dio pour faire des requêtes réseau
  final Dio _dio;

  // === Constructeur ===
  // Initialise le client Dio avec les configurations de base
  MoodService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10), // Timeout de connexion
          receiveTimeout: const Duration(seconds: 10), // Timeout de réception
          headers: {
            'Content-Type': 'application/json', // Format des données
            'Accept': 'application/json',
          },
        ),
      );

  // ============================================
  // MÉTHODE 1 : RÉCUPÉRER TOUTES LES HUMEURS
  // ============================================
  // Requête : GET /api/moods
  // Retour : Liste de toutes les humeurs
  Future<List<Mood>> getMoods() async {
    try {
      // Effectue la requête GET
      final response = await _dio.get('/api/moods');

      // Si la requête réussit (code 200)
      if (response.statusCode == 200) {
        // Récupère les données (qui sont une liste)
        List<dynamic> data = response.data;

        // Convertit chaque élément JSON en objet Mood
        return data.map((json) => Mood.fromJson(json)).toList();
      } else {
        // Si le code n'est pas 200, il y a une erreur
        throw Exception('Échec du chargement des humeurs');
      }
    } catch (e) {
      // En cas d'erreur (réseau, timeout, etc.)
      throw Exception('Erreur lors de la récupération des humeurs: $e');
    }
  }

  // ============================================
  // MÉTHODE 2 : CRÉER UNE NOUVELLE HUMEUR
  // ============================================
  // Requête : POST /api/moods
  // Paramètre : mood (objet Mood à créer)
  // Retour : L'humeur créée (avec les données du serveur)
  Future<Mood> createMood(Mood mood) async {
    try {
      // Effectue la requête POST avec les données de l'humeur
      final response = await _dio.post(
        '/api/moods',
        data: mood.toJson(), // Convertit l'objet Mood en JSON
      );

      // Si la création réussit (code 200 ou 201)
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Retourne l'humeur créée
        return Mood.fromJson(response.data);
      } else {
        throw Exception('Échec de la création de l\'humeur');
      }
    } catch (e) {
      throw Exception('Erreur lors de la création: $e');
    }
  }

  // ============================================
  // MÉTHODE 3 : MODIFIER UNE HUMEUR EXISTANTE
  // ============================================
  // Requête : PUT /api/moods/{email}/{date}
  // Paramètres :
  //   - email : identifiant de l'utilisateur
  //   - date : date de l'humeur à modifier
  //   - mood : nouvelles données de l'humeur
  Future<Mood> updateMood(String email, DateTime date, Mood mood) async {
    try {
      // Convertit la date en format ISO8601 pour l'URL
      final dateStr = date.toIso8601String();

      // Effectue la requête PUT
      final response = await _dio.put(
        '/api/moods/$email/$dateStr',
        data: mood.toJson(),
      );

      // Si la modification réussit
      if (response.statusCode == 200) {
        return Mood.fromJson(response.data);
      } else {
        throw Exception('Échec de la modification de l\'humeur');
      }
    } catch (e) {
      throw Exception('Erreur lors de la modification: $e');
    }
  }

  // ============================================
  // MÉTHODE 4 : SUPPRIMER UNE HUMEUR
  // ============================================
  // Requête : DELETE /api/moods/{email}/{date}
  // Paramètres :
  //   - email : identifiant de l'utilisateur
  //   - date : date de l'humeur à supprimer
  Future<void> deleteMood(String email, DateTime date) async {
    try {
      final dateStr = date.toIso8601String();

      // Effectue la requête DELETE
      final response = await _dio.delete('/api/moods/$email/$dateStr');

      // Vérifie que la suppression a réussi (code 200 ou 204)
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Échec de la suppression de l\'humeur');
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }
}
