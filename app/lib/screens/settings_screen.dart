import 'package:flutter/material.dart';
import '../theme/theme_manager.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/household_repository.dart';
import '../services/audio_service.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;
  final AuthService authService;
  final HouseholdRepository householdRepo;
  final AudioService? audioService;

  static List<MissionAudioTrack> get selectableTracks => RealAudioService.missionTracks;

  const SettingsScreen({
    super.key,
    required this.userId,
    required this.authService,
    required this.householdRepo,
    this.audioService,
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final AudioService _audioService;

  UserProfile? _userProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _audioService = widget.audioService ?? RealAudioService();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;
    setState(() => _isLoadingProfile = true);
    try {
      final profile = await widget.householdRepo.getUserProfile(widget.userId);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoadingProfile = false;
        });
      }
      if (profile != null && profile.selectedAudioTrack.isNotEmpty) {
        if (_audioService.selectedTrack != profile.selectedAudioTrack) {
          await _audioService.setSelectedTrack(profile.selectedAudioTrack);
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _navigateToOnboarding() async {
    await _audioService.stopTrackPreview();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingScreen(
          userId: widget.userId,
          householdRepo: widget.householdRepo,
          onComplete: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
    if (mounted) {
      await _loadUserProfile();
    }
  }

  @override
  void dispose() {
    _audioService.stopTrackPreview();
    super.dispose();
  }

  Future<void> _toggleTrackPreview(String assetPath) async {
    final active = _audioService.previewingTrackNotifier.value;
    if (active != null &&
        (active == assetPath ||
         RealAudioService.resolveTrackPath(active) == RealAudioService.resolveTrackPath(assetPath))) {
      await _audioService.stopTrackPreview();
    } else {
      await _audioService.playTrackPreview(assetPath);
    }
  }

  Future<void> _selectTrack(String track) async {
    await _audioService.stopTrackPreview();
    await _audioService.setSelectedTrack(track);
    try {
      final profile = await widget.householdRepo.getUserProfile(widget.userId);
      if (profile != null) {
        final updated = profile.copyWith(selectedAudioTrack: track);
        await widget.householdRepo.saveUserProfile(updated);
        if (mounted) {
          setState(() {
            _userProfile = updated;
          });
        }
      } else {
        final newProfile = UserProfile(
          userId: widget.userId,
          selectedAudioTrack: track,
        );
        await widget.householdRepo.saveUserProfile(newProfile);
        if (mounted) {
          setState(() {
            _userProfile = newProfile;
          });
        }
      }
    } catch (e) {
      debugPrint('Error updating user profile audio track: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'CONFIGURATION SYSTÈME',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.black87,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. TOP POSITION (#1 Priority): 🧹 CONFIGURATION DES CORVÉES
          _buildSectionTitle('🧹 Configuration des Corvées'),
          _buildHomeConfig(),
          const SizedBox(height: 24),

          // 2. SECOND POSITION (#2 Priority): 🎧 AUDIO & AMBIANCES
          _buildSectionTitle('🎧 Audio & Ambiances'),
          _buildAudioOptions(),
          const SizedBox(height: 24),

          // 3. THIRD POSITION (#3 Priority): 🎨 THÈMES VISUELS
          _buildSectionTitle('🎨 Thèmes Visuels'),
          _buildThemeSelector(),
          const SizedBox(height: 24),

          // 4. BOTTOM POSITION (#4 Priority): 👤 PROFIL, CRÉDITS & DÉCONNEXION
          _buildSectionTitle('👤 Dossier Soldat & Système'),
          _buildProfile(),
          const SizedBox(height: 14),
          _buildAudioCredits(),
          const SizedBox(height: 14),
          _buildLogoutCard(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  // #1 Priority: Prominent Tactical Action Card for Home / Chores configuration
  Widget _buildHomeConfig() {
    final primaryColor = Theme.of(context).primaryColor;

    return Card(
      color: const Color(0xFF1A1A1A),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: primaryColor.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _navigateToOnboarding,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Icon(Icons.cleaning_services, color: primaryColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Configuration des Corvées',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ÉDITEUR',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Personnaliser les pièces, tâches, fréquences et durées',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, color: primaryColor, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // #2 Priority: Clean, grouped tactical card for audio settings
  Widget _buildAudioOptions() {
    return Card(
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle 1: Ambiance Générale de l'App
          ValueListenableBuilder<bool>(
            valueListenable: _audioService.appAmbianceNotifier,
            builder: (context, appAmbianceEnabled, child) {
              return SwitchListTile(
                title: const Text(
                  'Ambiance Générale de l\'App',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  appAmbianceEnabled
                      ? 'Activée (fond sonore subtil de passerelle de commandement)'
                      : 'Désactivée (accueil silencieux)',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                value: appAmbianceEnabled,
                onChanged: (val) {
                  _audioService.toggleAppAmbiance();
                },
                activeThumbColor: Theme.of(context).primaryColor,
              );
            },
          ),
          const Divider(color: Colors.white10, height: 1),

          // Toggle 2: Musique de Mission (Timer)
          ValueListenableBuilder<bool>(
            valueListenable: _audioService.missionMusicNotifier,
            builder: (context, missionMusicEnabled, child) {
              return SwitchListTile(
                title: const Text(
                  'Musique de Mission (Timer)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  missionMusicEnabled
                      ? 'Activée (bande-son tactique pendant les missions)'
                      : 'Désactivée (missions sans musique)',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                value: missionMusicEnabled,
                onChanged: (val) {
                  _audioService.toggleMissionMusic();
                },
                activeThumbColor: Theme.of(context).primaryColor,
              );
            },
          ),
          const Divider(color: Colors.white10, height: 1),

          // Toggle 3: Bruitages d'action (SFX)
          ValueListenableBuilder<bool>(
            valueListenable: _audioService.sfxEnabledNotifier,
            builder: (context, sfxEnabled, child) {
              return SwitchListTile(
                title: const Text(
                  'Bruitages d\'action (SFX)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  sfxEnabled ? 'Activé (clics, validations, victoires)' : 'Désactivé (mode silencieux)',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                value: sfxEnabled,
                onChanged: (val) {
                  _audioService.toggleSfx();
                },
                activeThumbColor: Theme.of(context).primaryColor,
              );
            },
          ),
          const Divider(color: Colors.white10, height: 1),

          // Sélecteur de Musique de Mission: Compact, readable list with play/preview button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'BANDE-SON DES MISSIONS (6 PISTES)',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'APERÇU DISPONIBLE',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<String>(
            valueListenable: _audioService.selectedTrackNotifier,
            builder: (context, selectedTrack, child) {
              return ValueListenableBuilder<String?>(
                valueListenable: _audioService.previewingTrackNotifier,
                builder: (context, previewingTrack, _) {
                  return Column(
                    children: SettingsScreen.selectableTracks.map((track) {
                      final bool isSelected = selectedTrack == track.assetPath;
                      final bool isPreviewing = previewingTrack != null &&
                          (previewingTrack == track.assetPath ||
                           previewingTrack == track.id ||
                           RealAudioService.resolveTrackPath(previewingTrack) == track.assetPath);

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.6), width: 1.2)
                              : Border.all(color: Colors.transparent),
                        ),
                        child: Material(
                          color: isSelected
                              ? Theme.of(context).primaryColor.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            leading: Radio<String>(
                              value: track.assetPath,
                              groupValue: selectedTrack,
                              activeColor: Theme.of(context).primaryColor,
                              onChanged: (val) {
                                if (val != null) _selectTrack(val);
                              },
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    track.title,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.white,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    margin: const EdgeInsets.only(left: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Theme.of(context).primaryColor, width: 0.8),
                                    ),
                                    child: Text(
                                      'ACTIF',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${track.subtitle} • ${track.artist}',
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                ),
                                if (isPreviewing)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: Text(
                                      '▶ LECTURE',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.secondary,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                isPreviewing ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                                color: isPreviewing
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context).primaryColor,
                                size: 30,
                              ),
                              tooltip: isPreviewing ? 'Arrêter l\'extrait' : 'Écouter un extrait',
                              onPressed: () => _toggleTrackPreview(track.assetPath),
                            ),
                            onTap: () => _selectTrack(track.assetPath),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // #3 Priority: Compact, clean theme selector
  Widget _buildThemeSelector() {
    return Card(
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white12),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          children: [
            _ThemeTile(type: AppThemeType.trench, name: 'Trench', primary: Color(0xFF6B8E23), secondary: Colors.amber),
            Divider(color: Colors.white10, height: 1),
            _ThemeTile(type: AppThemeType.neonOps, name: 'Neon-Ops', primary: Colors.cyanAccent, secondary: Colors.pinkAccent),
            Divider(color: Colors.white10, height: 1),
            _ThemeTile(type: AppThemeType.ghost, name: 'Ghost', primary: Colors.white, secondary: Color(0xFFD32F2F)),
          ],
        ),
      ),
    );
  }

  // #4 Priority: Dynamic Profile Stats (Medals, Credits, Level, Agent Name)
  Widget _buildProfile() {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final secondaryColor = theme.colorScheme.secondary;

    final agentName = _userProfile?.agentName.trim().isNotEmpty == true
        ? _userProfile!.agentName
        : 'Nettoyeur-1';
    final medals = _userProfile?.medals ?? 0;
    final credits = _userProfile?.credits ?? 0;
    final level = _userProfile?.level ?? 1;

    return Card(
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: primaryColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(Icons.military_tech, color: secondaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Statistiques du soldat',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'AGENT : ${agentName.toUpperCase()}',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoadingProfile)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryColor,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: primaryColor, width: 1),
                    ),
                    child: Text(
                      'RANG $level',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildTacticalStatPill(
                    icon: Icons.shield_rounded,
                    label: 'NIVEAU',
                    value: '$level',
                    accentColor: primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTacticalStatPill(
                    icon: Icons.emoji_events_rounded,
                    label: 'MÉDAILLES',
                    value: '$medals',
                    accentColor: secondaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTacticalStatPill(
                    icon: Icons.monetization_on_rounded,
                    label: 'CRÉDITS',
                    value: '$credits',
                    accentColor: Colors.amberAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTacticalStatPill({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: accentColor, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: accentColor.withValues(alpha: 0.8),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  // Audio Credits & Licenses card
  Widget _buildAudioCredits() {
    return Card(
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.library_music, color: Theme.of(context).primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Crédits Audio & Licences',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildCreditItem(
              title: 'Piste 1 (Alpha): "Epic Battle"',
              artist: 'Cj Aist',
              license: 'Licence CC BY 3.0',
              description: 'Rythme martial, percussions tactiques et ambiance d\'assaut (tactical_ambiance_1.mp3)',
            ),
            const Divider(color: Colors.white10, height: 16),
            _buildCreditItem(
              title: 'Piste 2 (Bravo): "Epic Questionmark"',
              artist: 'Antti Luode',
              license: 'Licence CC BY 3.0',
              description: 'Tension opérationnelle, cordes dramatiques & marche héroïque (tactical_ambiance_2.mp3)',
            ),
            const Divider(color: Colors.white10, height: 16),
            _buildCreditItem(
              title: 'Piste 3 (Charlie): "Not So Epic / Heavy Recon"',
              artist: 'Antti Luode',
              license: 'Licence CC BY 3.0',
              description: 'Infiltration lourde, basse industrielle & suspense tactique (tactical_ambiance_3.mp3)',
            ),
            const Divider(color: Colors.white10, height: 16),
            _buildCreditItem(
              title: 'Piste 4 (Delta): "Dark Synth"',
              artist: 'Antti Luode',
              license: 'Licence CC BY 3.0',
              description: 'Ondes synthétiques sombres & pulsation cybernétique (tactical_ambiance_4.mp3)',
            ),
            const Divider(color: Colors.white10, height: 16),
            _buildCreditItem(
              title: 'Piste 5 (Echo): "Future City"',
              artist: 'Antti Luode',
              license: 'Licence CC BY 3.0',
              description: 'Électro futuriste & cadence d\'intervention d\'urgence (tactical_ambiance_5.mp3)',
            ),
            const Divider(color: Colors.white10, height: 16),
            _buildCreditItem(
              title: 'Piste 6 (Foxtrot): "Space Dominator Squadron"',
              artist: 'Antti Luode',
              license: 'Licence CC BY 3.0',
              description: 'Assaut spatial & dynamique d\'action critique sous pression (tactical_ambiance_6.mp3)',
            ),
            const Divider(color: Colors.white10, height: 16),
            _buildCreditItem(
              title: 'Passerelle de Commandement (Bridge Ambiance): "The Bridge"',
              artist: 'Antti Luode',
              license: 'Licence CC BY 3.0',
              description: 'Atmosphère sonore et boucle d\'ambiance continue de la passerelle (bridge_ambiance.mp3)',
            ),
            const Divider(color: Colors.white10, height: 16),
            _buildCreditItem(
              title: 'Signal de Déploiement (Tactical Deploy)',
              artist: 'Mil-Tech Sound System',
              license: 'Licence CC0 1.0 Universal',
              description: 'Carillon et signal sonore d\'engagement de mission (deploy.wav)',
            ),
            const Divider(color: Colors.white10, height: 16),
            _buildCreditItem(
              title: 'Fanfare de Victoire (Victory Fanfare)',
              artist: 'Mil-Tech Sound System',
              license: 'Licence CC0 1.0 Universal',
              description: 'Hymne martial et célébration de victoire (victory.wav)',
            ),
            const Divider(color: Colors.white10, height: 16),
            _buildCreditItem(
              title: 'Effets Sonores Tactiques (SFX Moteur)',
              artist: 'Mil-Tech Audio Division / Sound Synthesis',
              license: 'Licence CC0 1.0 Universal',
              description: 'Signaux acoustiques: balayage (swipe.wav), clics et retours haptico-sonores',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditItem({
    required String title,
    required String artist,
    required String license,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2.0, right: 6.0),
              child: Icon(Icons.music_note, color: Theme.of(context).primaryColor, size: 14),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$title\n',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    TextSpan(
                      text: 'Artiste: $artist  •  $license\n',
                      style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 11),
                    ),
                    TextSpan(
                      text: description,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Red "Déconnexion" button at the very bottom
  Widget _buildLogoutCard() {
    return Card(
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: ListTile(
        leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
        title: Text(
          'Déconnexion',
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        subtitle: const Text(
          'Mettre fin à la session tactique en cours',
          style: TextStyle(color: Colors.white54, fontSize: 11),
        ),
        trailing: Icon(Icons.exit_to_app, color: Theme.of(context).colorScheme.error, size: 20),
        onTap: () async {
          await _audioService.stopTrackPreview();
          await widget.authService.signOut();
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final AppThemeType type;
  final String name;
  final Color primary;
  final Color secondary;

  const _ThemeTile({
    required this.type,
    required this.name,
    required this.primary,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = ThemeProvider.of(context).currentTheme.type == type;

    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1.2),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: secondary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1.2),
            ),
          ),
        ],
      ),
      title: Text(
        name,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.white70,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Theme.of(context).primaryColor, width: 1.5),
              ),
              child: Text(
                '[ACTIF]',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Icon(Icons.check_circle, color: Theme.of(context).primaryColor, size: 22),
          ] else
            const Icon(Icons.circle_outlined, color: Colors.white24, size: 18),
        ],
      ),
      tileColor: isActive ? Theme.of(context).primaryColor.withValues(alpha: 0.12) : null,
      shape: isActive
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Theme.of(context).primaryColor, width: 2.0),
            )
          : null,
      onTap: () {
        ThemeProvider.of(context, listen: false).setTheme(type);
      },
    );
  }
}
