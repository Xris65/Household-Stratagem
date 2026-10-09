with open("lib/screens/home_screen.dart", "a", encoding="utf-8") as f:
    f.write("""
class _ThemeTile extends StatelessWidget {
  final AppThemeType type;
  final String name;
  final Color primary;
  final Color secondary;

  const _ThemeTile({
    Key? key,
    required this.type,
    required this.name,
    required this.primary,
    required this.secondary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 24, height: 24,
        decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
      ),
      title: Text(name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      trailing: Container(
        width: 12, height: 12,
        decoration: BoxDecoration(color: secondary, shape: BoxShape.circle),
      ),
      onTap: () {
        ThemeManager.of(context)?.setTheme(type);
        Navigator.pop(context);
      },
    );
  }
}
""")
