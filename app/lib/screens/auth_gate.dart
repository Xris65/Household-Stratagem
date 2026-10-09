import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/household_repository.dart';
import '../widgets/tactical_loader.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';

class AuthGate extends StatefulWidget {
  final AuthService authService;
  final HouseholdRepository householdRepo;

  const AuthGate({super.key, required this.authService, required this.householdRepo});

  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      await widget.authService.signInWithEmailPassword(email, password);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auth failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginGuest() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Entrez votre nom'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(hintText: 'Votre nom'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: Text('Continuer'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final userId = await widget.authService.signInAnonymously();
      if (userId.isNotEmpty) {
        final profile = UserProfile(
          userId: userId,
          agentName: name,
          level: 1,
          onboarded: false,
        );
        await widget.householdRepo.saveUserProfile(profile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Échec de la connexion invitée: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool>? _onboardingFuture;
  String? _lastUserId;

  Future<bool> _hasCompletedOnboarding(String userId) async {
    final profile = await widget.householdRepo.getUserProfile(userId);
    if (profile != null && profile.onboarded) {
      return true;
    }
    
    final chores = await widget.householdRepo.getChores(userId);
    return chores.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: widget.authService.authStateChanges,
      builder: (context, snapshot) {
        final userId = snapshot.data ?? widget.authService.currentUserId;
        
        if (userId == null) {
          return Scaffold(
            appBar: AppBar(title: Text('Connexion')),
            body: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('CONNEXION', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    SizedBox(height: 40),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: 'Mot de passe', border: OutlineInputBorder()),
                      obscureText: true,
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                    SizedBox(height: 30),
                    if (_isLoading)
                      Center(child: TacticalLoader())
                    else ...[
                      ElevatedButton(
                        onPressed: _loginEmail,
                        child: Text('Se connecter / S\'inscrire'),
                      ),
                      SizedBox(height: 16),
                      TextButton(
                        onPressed: _loginGuest,
                        child: Text('Continuer en tant qu\'invité', style: TextStyle(color: Colors.white70)),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          );
        }

        if (_lastUserId != userId || _onboardingFuture == null) {
          _lastUserId = userId;
          _onboardingFuture = _hasCompletedOnboarding(userId);
        }

        return FutureBuilder<bool>(
          future: _onboardingFuture,
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(backgroundColor: Color(0xFF050505), body: Center(child: TacticalLoader()));
            }
            if (profileSnapshot.hasError) {
              return Scaffold(
                backgroundColor: Color(0xFF050505),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'Erreur de chargement du profil',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          profileSnapshot.error.toString(),
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _onboardingFuture = _hasCompletedOnboarding(userId);
                            });
                          },
                          icon: Icon(Icons.refresh),
                          label: Text('Réessayer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            if (profileSnapshot.data == true) {
              return HomeScreen(
                userId: userId,
                householdRepo: widget.householdRepo,
                authService: widget.authService,
              );
            } else {
              return OnboardingScreen(
                userId: userId,
                householdRepo: widget.householdRepo,
                onComplete: () {
                  if (mounted) {
                    setState(() {
                      _onboardingFuture = Future.value(true);
                    });
                  }
                },
              );
            }
          },
        );
      },
    );
  }
}


