import 'package:flutter/material.dart';
import '../services/household_repository.dart';
import '../models/user_profile.dart';
import '../models/chore.dart';
import '../models/room_category.dart';
import '../widgets/tactical_loader.dart';

class OnboardingScreen extends StatefulWidget {
  final String userId;
  final HouseholdRepository householdRepo;
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.userId,
    required this.householdRepo,
    required this.onComplete,
  });

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  List<Chore> _chores = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingConfig();
  }

  Future<void> _loadExistingConfig() async {
    final existing = await widget.householdRepo.getChores(widget.userId);
    if (existing.isNotEmpty) {
      if (mounted) {
        setState(() {
        _chores = existing;
        _isLoading = false;
      });
      }
      return;
    }
    
    // Default fallback if no config exists
    if (mounted) {
      setState(() {
      _chores = _getDefaultChores();
      _isLoading = false;
    });
    }
  }

  List<Chore> _getDefaultChores() {
    return RoomCategory.defaultChores;
  }

  void _resetChore(int index) {
    final choreId = _chores[index].id;
    final defaultChore = _getDefaultChores().firstWhere((c) => c.id == choreId, orElse: () => _chores[index]);
    setState(() {
      _chores[index] = defaultChore;
    });
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isSaving = true);
    try {
      final existingProfile = await widget.householdRepo.getUserProfile(widget.userId);
      final profile = existingProfile?.copyWith(onboarded: true) ?? UserProfile(
        userId: widget.userId,
        agentName: 'Utilisateur',
        level: 1,
        onboarded: true,
      );
      await widget.householdRepo.saveUserProfile(profile);
      
      final selectedChores = _chores.where((c) => c.enabled).toList();
      debugPrint("=== START _completeOnboarding ===");
      debugPrint("User ID: ${widget.userId}");
      debugPrint("Selected Chores Count: ${selectedChores.length}");
      await widget.householdRepo.saveChores(widget.userId, selectedChores);

      if (mounted) {
        widget.onComplete();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _updatePeriodicity(int index, int delta) {
    setState(() {
      int newPeriod = _chores[index].periodicityDays + delta;
      if (newPeriod < 1) newPeriod = 1;
      _chores[index] = _chores[index].copyWith(periodicityDays: newPeriod);
    });
  }

  void _updateDuration(int index, int delta) {
    setState(() {
      int newDuration = _chores[index].durationMinutes + delta;
      if (newDuration < 1) newDuration = 1;
      _chores[index] = _chores[index].copyWith(durationMinutes: newDuration);
    });
  }

  void _toggleChore(int index, bool? value) {
    setState(() {
      _chores[index] = _chores[index].copyWith(enabled: value ?? true);
    });
  }

  final List<String> _customRooms = [];

  void _deleteChore(int index) {
    setState(() {
      _chores.removeAt(index);
    });
  }

  void _addChore(String room) async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF141414),
        title: Text('Nouvelle tâche', style: TextStyle(color: Theme.of(context).primaryColor)),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nom de la tâche',
            hintStyle: TextStyle(color: Colors.white30),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: Text('Ajouter', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      setState(() {
        _chores.add(Chore(
          id: 'c_custom_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          room: room,
          difficulty: 1,
          periodicityDays: 7,
          enabled: true,
        ));
      });
    }
  }

  void _addRoom() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF141414),
        title: Text('Nouvelle Pièce', style: TextStyle(color: Theme.of(context).primaryColor)),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nom de la pièce',
            hintStyle: TextStyle(color: Colors.white30),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: Text('Ajouter', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      setState(() {
        if (!_customRooms.contains(name)) {
          _customRooms.add(name);
        }
      });
    }
  }

  void _deleteRoom(String room) {
    setState(() {
      _chores.removeWhere((c) => c.room == room);
      _customRooms.remove(room);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: TacticalLoader()),
      );
    }

    final grouped = <String, List<int>>{};
    for (int i = 0; i < _chores.length; i++) {
      grouped.putIfAbsent(_chores[i].room, () => []).add(i);
    }
    for (final room in _customRooms) {
      grouped.putIfAbsent(room, () => []);
    }
    
    final rooms = grouped.keys.toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('L\'Armurerie', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(color: Theme.of(context).primaryColor.withValues(alpha: 0.5), height: 1.0),
        ),
      ),
      body: _isSaving 
        ? Center(child: TacticalLoader()) 
        : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(top: 16, bottom: 16),
              itemCount: rooms.length,
              itemBuilder: (context, roomIndex) {
                final room = rooms[roomIndex];
                final choreIndices = grouped[room]!;
                
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                        blurRadius: 8.0,
                        spreadRadius: 1.0,
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: roomIndex == 0,
                      iconColor: Theme.of(context).colorScheme.secondary,
                      collapsedIconColor: Theme.of(context).primaryColor,
                      title: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(room, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.1)),
                                SizedBox(height: 4),
                                Text('${choreIndices.length} tâches', style: TextStyle(color: Theme.of(context).primaryColor.withValues(alpha: 0.6), fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                            onPressed: () => _deleteRoom(room),
                            tooltip: 'Supprimer la pièce',
                          )
                        ],
                      ),
                      children: [
                        ...choreIndices.map((index) {
                          final chore = _chores[index];
                          final textColor = chore.enabled ? (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white) : Colors.white30;
                          
                          return Container(
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.1))),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Checkbox(
                                        value: chore.enabled,
                                        onChanged: (val) => _toggleChore(index, val),
                                        activeColor: Theme.of(context).colorScheme.secondary,
                                        checkColor: Colors.black,
                                        side: BorderSide(color: Theme.of(context).primaryColor),
                                      ),
                                      Expanded(
                                        child: Text(chore.name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.restore, color: Theme.of(context).colorScheme.secondary, size: 20),
                                            onPressed: () => _resetChore(index),
                                            tooltip: 'Réinitialiser',
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(),
                                          ),
                                          SizedBox(width: 16),
                                          IconButton(
                                            icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 20),
                                            onPressed: () => _deleteChore(index),
                                            tooltip: 'Supprimer la tâche',
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _buildControlPill(
                                            context,
                                            icon: Icons.calendar_today,
                                            value: '${chore.periodicityDays} j',
                                            onDecrease: chore.enabled ? () => _updatePeriodicity(index, -1) : null,
                                            onIncrease: chore.enabled ? () => _updatePeriodicity(index, 1) : null,
                                            enabled: chore.enabled,
                                          ),
                                          _buildControlPill(
                                            context,
                                            icon: Icons.timer,
                                            value: '${chore.durationMinutes} min',
                                            onDecrease: chore.enabled ? () => _updateDuration(index, -5) : null,
                                            onIncrease: chore.enabled ? () => _updateDuration(index, 5) : null,
                                            enabled: chore.enabled,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.1)))),
                          child: TextButton.icon(
                            icon: Icon(Icons.add, color: Theme.of(context).colorScheme.secondary),
                            label: Text('Ajouter une tâche', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                            onPressed: () => _addChore(room),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.2))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      onPressed: _addRoom,
                      icon: Icon(Icons.add, color: Theme.of(context).primaryColor, size: 20),
                      label: Text('Pièce', style: TextStyle(color: Theme.of(context).primaryColor)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).primaryColor),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _completeOnboarding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 4,
                      ),
                      child: Text('VALIDER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPill(
    BuildContext context, {
    required IconData icon,
    required String value,
    required VoidCallback? onDecrease,
    required VoidCallback? onIncrease,
    required bool enabled,
  }) {
    final activeColor = Theme.of(context).primaryColor;
    final inactiveColor = Theme.of(context).primaryColor.withValues(alpha: 0.3);
    final displayColor = enabled ? activeColor : inactiveColor;
    final bgColor = enabled ? activeColor.withValues(alpha: 0.1) : Colors.transparent;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: displayColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onDecrease,
            borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.remove, size: 16, color: enabled ? Theme.of(context).colorScheme.error : inactiveColor),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: displayColor),
                SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: displayColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onIncrease,
            borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.add, size: 16, color: enabled ? Colors.greenAccent : inactiveColor),
            ),
          ),
        ],
      ),
    );
  }
}


