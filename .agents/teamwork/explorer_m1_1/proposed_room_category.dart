import 'chore.dart';

/// Metadata for a room category in the household tactical map.
class RoomMetadata {
  final String name;
  final String description;
  final String iconKey;
  final int defaultTaskCount;

  const RoomMetadata({
    required this.name,
    required this.description,
    required this.iconKey,
    required this.defaultTaskCount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomMetadata &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          description == other.description &&
          iconKey == other.iconKey &&
          defaultTaskCount == other.defaultTaskCount;

  @override
  int get hashCode => Object.hash(name, description, iconKey, defaultTaskCount);

  @override
  String toString() => 'RoomMetadata(name: "$name", iconKey: "$iconKey")';
}

/// Constants, metadata and default chore catalogue for the 4 core household rooms.
class RoomCategory {
  static const String cuisine = 'Cuisine';
  static const String salleDeBain = 'Salle de bain';
  static const String salon = 'Salon';
  static const String chambre = 'Chambre';

  /// The 4 mandatory room categories defined in project specifications.
  static const List<String> all = [
    cuisine,
    salleDeBain,
    salon,
    chambre,
  ];

  /// Alias for [all].
  static const List<String> rooms = all;

  /// Room metadata definitions (tactical cleaning theme).
  static const Map<String, RoomMetadata> metadata = {
    cuisine: RoomMetadata(
      name: cuisine,
      description: 'Dégraissage, désinfection et gestion des résidus alimentaires',
      iconKey: 'kitchen',
      defaultTaskCount: 5,
    ),
    salleDeBain: RoomMetadata(
      name: salleDeBain,
      description: 'Détartrage, assainissement et élimination de l\'humidité',
      iconKey: 'bathtub',
      defaultTaskCount: 4,
    ),
    salon: RoomMetadata(
      name: salon,
      description: 'Aspiration, dépoussiérage et maintien du confort tactique',
      iconKey: 'weekend',
      defaultTaskCount: 4,
    ),
    chambre: RoomMetadata(
      name: chambre,
      description: 'Aération, renouvellement des textiles et assainissement',
      iconKey: 'bed',
      defaultTaskCount: 4,
    ),
  };

  /// Returns metadata for the given room, or null if not recognized.
  static RoomMetadata? getMetadata(String room) => metadata[room];

  /// Validates whether a room string belongs to the official 4 categories.
  static bool isValid(String room) => all.contains(room);

  /// Catalogue of 17 predefined default chores with dynamic 5-8 swipe sequences.
  static List<Chore> get defaultChores => [
        // --- CUISINE (5 tâches) ---
        Chore(
          id: 'cuisine_degraissage_four',
          name: 'Dégraissage four & plaques',
          room: cuisine,
          difficulty: 3,
          periodicityDays: 7,
          stratagemSequence: ['UP', 'RIGHT', 'DOWN', 'DOWN', 'LEFT'],
          isDefault: true,
        ),
        Chore(
          id: 'cuisine_nettoyage_evier',
          name: 'Nettoyer évier & plan de travail',
          room: cuisine,
          difficulty: 2,
          periodicityDays: 2,
          stratagemSequence: ['LEFT', 'RIGHT', 'LEFT', 'RIGHT', 'UP'],
          isDefault: true,
        ),
        Chore(
          id: 'cuisine_sortir_poubelles',
          name: 'Sortir les poubelles & tri',
          room: cuisine,
          difficulty: 1,
          periodicityDays: 1,
          stratagemSequence: ['DOWN', 'DOWN', 'UP', 'RIGHT', 'UP'],
          isDefault: true,
        ),
        Chore(
          id: 'cuisine_detartrage_cafetiere',
          name: 'Détartrer la cafetière',
          room: cuisine,
          difficulty: 2,
          periodicityDays: 14,
          stratagemSequence: ['UP', 'LEFT', 'DOWN', 'RIGHT', 'UP', 'DOWN'],
          isDefault: true,
        ),
        Chore(
          id: 'cuisine_refrigerateur',
          name: 'Nettoyage intérieur du réfrigérateur',
          room: cuisine,
          difficulty: 4,
          periodicityDays: 30,
          stratagemSequence: ['UP', 'RIGHT', 'DOWN', 'LEFT', 'UP', 'RIGHT', 'DOWN'],
          isDefault: true,
        ),

        // --- SALLE DE BAIN (4 tâches) ---
        Chore(
          id: 'sdb_detartrage_douche',
          name: 'Détartrage douche & robinetterie',
          room: salleDeBain,
          difficulty: 4,
          periodicityDays: 7,
          stratagemSequence: ['DOWN', 'UP', 'LEFT', 'RIGHT', 'DOWN', 'UP'],
          isDefault: true,
        ),
        Chore(
          id: 'sdb_lavabo_miroir',
          name: 'Nettoyer lavabo & miroir',
          room: salleDeBain,
          difficulty: 2,
          periodicityDays: 3,
          stratagemSequence: ['LEFT', 'UP', 'RIGHT', 'DOWN', 'UP'],
          isDefault: true,
        ),
        Chore(
          id: 'sdb_desinfection_wc',
          name: 'Désinfection sanitaires & WC',
          room: salleDeBain,
          difficulty: 3,
          periodicityDays: 2,
          stratagemSequence: ['DOWN', 'DOWN', 'LEFT', 'RIGHT', 'DOWN'],
          isDefault: true,
        ),
        Chore(
          id: 'sdb_tapis_serviettes',
          name: 'Laver tapis de bain & serviettes',
          room: salleDeBain,
          difficulty: 1,
          periodicityDays: 7,
          stratagemSequence: ['UP', 'DOWN', 'UP', 'DOWN', 'RIGHT'],
          isDefault: true,
        ),

        // --- SALON (4 tâches) ---
        Chore(
          id: 'salon_aspiration_tapis',
          name: 'Passer l\'aspirateur & tapis',
          room: salon,
          difficulty: 2,
          periodicityDays: 3,
          stratagemSequence: ['LEFT', 'LEFT', 'RIGHT', 'RIGHT', 'UP'],
          isDefault: true,
        ),
        Chore(
          id: 'salon_depoussierage',
          name: 'Dépoussiérer meubles & étagères',
          room: salon,
          difficulty: 2,
          periodicityDays: 7,
          stratagemSequence: ['UP', 'RIGHT', 'UP', 'LEFT', 'DOWN'],
          isDefault: true,
        ),
        Chore(
          id: 'salon_vitres',
          name: 'Laver les vitres & baies',
          room: salon,
          difficulty: 4,
          periodicityDays: 30,
          stratagemSequence: ['RIGHT', 'UP', 'LEFT', 'DOWN', 'RIGHT', 'UP', 'DOWN', 'LEFT'],
          isDefault: true,
        ),
        Chore(
          id: 'salon_canape',
          name: 'Nettoyer & aérer le canapé',
          room: salon,
          difficulty: 3,
          periodicityDays: 14,
          stratagemSequence: ['DOWN', 'LEFT', 'UP', 'RIGHT', 'DOWN', 'LEFT'],
          isDefault: true,
        ),

        // --- CHAMBRE (4 tâches) ---
        Chore(
          id: 'chambre_changer_draps',
          name: 'Changer draps & housses de couette',
          room: chambre,
          difficulty: 2,
          periodicityDays: 7,
          stratagemSequence: ['UP', 'UP', 'DOWN', 'DOWN', 'LEFT', 'RIGHT'],
          isDefault: true,
        ),
        Chore(
          id: 'chambre_aspiration_sol',
          name: 'Aspiration & lavage du sol',
          room: chambre,
          difficulty: 2,
          periodicityDays: 4,
          stratagemSequence: ['DOWN', 'RIGHT', 'LEFT', 'UP', 'DOWN'],
          isDefault: true,
        ),
        Chore(
          id: 'chambre_penderie',
          name: 'Rangement & tri de la penderie',
          room: chambre,
          difficulty: 3,
          periodicityDays: 14,
          stratagemSequence: ['LEFT', 'UP', 'RIGHT', 'UP', 'LEFT', 'DOWN'],
          isDefault: true,
        ),
        Chore(
          id: 'chambre_tables_chevet',
          name: 'Dépoussiérer tables de chevet & lampes',
          room: chambre,
          difficulty: 1,
          periodicityDays: 7,
          stratagemSequence: ['RIGHT', 'LEFT', 'DOWN', 'UP', 'RIGHT'],
          isDefault: true,
        ),
      ];

  /// Filters default chores for a specific room.
  static List<Chore> defaultChoresForRoom(String room) {
    return defaultChores.where((chore) => chore.room == room).toList();
  }
}
