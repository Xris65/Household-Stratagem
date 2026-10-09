import re

with open('lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix ThemeProvider
content = content.replace("ThemeManager.of(context)?.setTheme(type);", "ThemeProvider.of(context, listen: false).setTheme(type);")

# Insert _showThemeSelector inside _HomeScreenState if missing
if "_showThemeSelector" not in content:
    # find where to insert it: maybe right before Widget build(BuildContext context)
    build_idx = content.find("  @override\n  Widget build(BuildContext context) {")
    if build_idx != -1:
        func = """
  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF141414),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Theme.of(context).primaryColor, width: 2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('SÉLECTIONNER UN THÈME', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2.0), textAlign: TextAlign.center),
              SizedBox(height: 24),
              _ThemeTile(type: AppThemeType.trench, name: 'Trench', primary: Color(0xFF6B8E23), secondary: Theme.of(context).colorScheme.secondary),
              _ThemeTile(type: AppThemeType.neonOps, name: 'Neon-Ops', primary: Theme.of(context).primaryColor, secondary: Colors.pinkAccent),
              _ThemeTile(type: AppThemeType.ghost, name: 'Ghost', primary: Colors.white, secondary: Color(0xFFD32F2F)),
            ],
          ),
        );
      },
    );
  }

"""
        content = content[:build_idx] + func + content[build_idx:]

with open('lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
