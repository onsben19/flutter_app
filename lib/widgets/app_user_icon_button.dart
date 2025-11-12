import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../screens/auth/login_screen.dart';

class AppUserIconButton extends StatefulWidget {
  const AppUserIconButton({super.key});

  @override
  State<AppUserIconButton> createState() => _AppUserIconButtonState();
}

class _AppUserIconButtonState extends State<AppUserIconButton> {
  SessionUser? _session; // <-- fix: was UserSession

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await SessionService.getLoggedInUser();
    if (!mounted) return;
    setState(() => _session = s);
  }

  Future<void> _showMenu(BuildContext context, Offset position) async {
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, 0),
      items: [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _session?.name ?? 'Utilisateur',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                _session?.email ?? '',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(Icons.logout),
            title: Text('Se déconnecter'),
          ),
        ),
      ],
    );

    if (selected == 'logout') {
      await SessionService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Compte',
      icon: const Icon(Icons.account_circle_outlined),
      onPressed: () async {
        // anchor the popup under the icon
        final box = context.findRenderObject() as RenderBox?;
        final offset = box?.localToGlobal(Offset.zero) ?? Offset.zero;
        await _showMenu(context, offset.translate(0, kToolbarHeight));
      },
    );
  }
}
