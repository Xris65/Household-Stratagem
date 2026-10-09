import 'package:flutter/material.dart';
import '../theme/theme_manager.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/household_repository.dart';
import '../services/audio_service.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;
  final AuthService authService;
  final HouseholdRepository householdRepo;

  const SettingsScreen({
    super.key,
    required this.userId,
    required this.authService,
    required this.householdRepo,
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Using a local instance of AudioService for toggles. In a real app this would be injected.
  final AudioService _audioService = RealAudioService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('CONFIGURATION SYSTÈME', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.black87,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('🎨 Thème & Visuels'),
          _buildThemeSelector(),
          SizedBox(height: 24),
          _buildSectionTitle('🎧 Options Sonores'),
          _buildAudioOptions(),
          SizedBox(height: 24),
          _buildSectionTitle('📜 Crédits Audio & Licences'),
          _buildAudioCredits(),
          SizedBox(height: 24),
          _buildSectionTitle('🏠 Configuration de la maison'),
          _buildHomeConfig(),
          SizedBox(height: 24),
          _buildSectionTitle('👤 Profil & Session'),
          _buildProfile(),
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

  Widget _buildThemeSelector() {
    return Card(
      color: Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white12)),
      child: Column(
        children: [
          _ThemeTile(type: AppThemeType.trench, name: 'Trench', primary: Color(0xFF6B8E23), secondary: Colors.amber),
          Divider(color: Colors.white10, height: 1),
          _ThemeTile(type: AppThemeType.neonOps, name: 'Neon-Ops', primary: Colors.cyanAccent, secondary: Colors.pinkAccent),
          Divider(color: Colors.white10, height: 1),
          _ThemeTile(type: AppThemeType.ghost, name: 'Ghost', primary: Colors.white, secondary: Color(0xFFD32F2F)),
        ],
      ),
    );
  }

  Widget _buildAudioOptions() {
    return Card(
      color: Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: _audioService.sfxEnabledNotifier,
            builder: (context, sfxEnabled, child) {
              return SwitchListTile(
                title: Text('Bruitages tactiques (SFX)', style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  sfxEnabled ? 'Activé (clics, validations, victoires)' : 'Désactivé (mode silencieux)',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                value: sfxEnabled,
                onChanged: (val) {
                  _audioService.toggleSfx();
                },
                activeThumbColor: Theme.of(context).primaryColor,
              );
            },
          ),
          Divider(color: Colors.white10, height: 1),
          ValueListenableBuilder<bool>(
            valueListenable: _audioService.musicEnabledNotifier,
            builder: (context, musicEnabled, child) {
              return SwitchListTile(
                title: Text('Musique de mission en fond', style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  musicEnabled ? 'Activé par défaut' : 'Désactivé',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                value: musicEnabled,
                onChanged: (val) {
                  _audioService.toggleMusic();
                },
                activeThumbColor: Theme.of(context).primaryColor,
              );
            },
          ),
          Divider(color: Colors.white10, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'BANDE-SON DES MISSIONS (3 PISTES)',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ),
          ValueListenableBuilder<String>(
            valueListenable: _audioService.selectedTrackNotifier,
            builder: (context, selectedTrack, child) {
              return Column(
                children: RealAudioService.missionTracks.map((track) {
                  return RadioListTile<String>(
                    value: track.assetPath,
                    groupValue: selectedTrack,
                    title: Text(track.title, style: TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: Text('${track.subtitle} • ${track.artist}', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (val) {
                      if (val != null) {
                        _audioService.setSelectedTrack(val);
                      }
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAudioCredits() {
    return Card(
      color: Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.library_music, color: Theme.of(context).primaryColor, size: 20),
                SizedBox(width: 8),
                Text('Crédits Audio & Licences', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            SizedBox(height: 12),
            Text('• Piste 1: "Epic Battle" par Cj Aist (Licence CC BY 3.0)', style: TextStyle(color: Colors.white70, fontSize: 12)),
            SizedBox(height: 6),
            Text('• Piste 2: "Epic Questionmark" par Antti Luode (Licence CC BY 3.0)', style: TextStyle(color: Colors.white70, fontSize: 12)),
            SizedBox(height: 6),
            Text('• Piste 3: "Not So Epic" par Antti Luode (Licence CC BY 3.0)', style: TextStyle(color: Colors.white70, fontSize: 12)),
            SizedBox(height: 6),
            Text('• Bruitages SFX: Moteur basse latence SoundPool Mil-Tech (swipe click, déploiement, victoire)', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeConfig() {
    return Card(
      color: Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white12)),
      child: ListTile(
        leading: Icon(Icons.home_repair_service, color: Theme.of(context).primaryColor),
        title: Text('Modifier les tâches', style: TextStyle(color: Colors.white)),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        onTap: () {
          Navigator.push(
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
        },
      ),
    );
  }

  Widget _buildProfile() {
    return Card(
      color: Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white12)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.military_tech, color: Theme.of(context).colorScheme.secondary),
            title: Text('Statistiques du soldat', style: TextStyle(color: Colors.white)),
            subtitle: Text('Médailles: 12 | Crédits: 450 | Niveau: 5', style: TextStyle(color: Colors.white54)),
          ),
          Divider(color: Colors.white10, height: 1),
          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text('Déconnexion', style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold)),
            onTap: () async {
              await widget.authService.signOut();
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
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
      leading: Container(
        width: 24, height: 24,
        decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
      ),
      title: Text(name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Theme.of(context).primaryColor),
              ),
              child: Text('[ACTIF]', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          if (isActive)
            Icon(Icons.check_circle, color: Theme.of(context).primaryColor, size: 20)
          else
            Container(
              width: 12, height: 12,
              decoration: BoxDecoration(color: secondary, shape: BoxShape.circle),
            ),
        ],
      ),
      tileColor: isActive ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
      shape: isActive ? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
      ) : null,
      onTap: () {
        ThemeProvider.of(context, listen: false).setTheme(type);
      },
    );
  }
}
