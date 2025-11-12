import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../theme/app_theme.dart';
import '../../services/group_repository.dart';
import '../../services/session_service.dart';

class GroupDetailScreen extends StatefulWidget {
  final Map<String, dynamic> group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final _repo = GroupRepository();

  bool _loading = true;
  bool _inviting = false;
  List<_MemberRow> _members = [];
  int? _currentUserId;
  bool _currentIsOwner = false;

  final _inviteController = TextEditingController();
  final _inviteFormKey = GlobalKey<FormState>();

  // Image state
  final _picker = ImagePicker();
  String? _imagePath; // local path saved in DB

  @override
  void initState() {
    super.initState();
    _imagePath = (widget.group['imagePath'] as String?)?.trim().isNotEmpty == true
        ? widget.group['imagePath'] as String
        : null;
    _loadAll();
  }

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final session = await SessionService.getLoggedInUser();
      _currentUserId = session?.id;

      final groupId = int.parse(widget.group['id'] as String);
      final rows = await _repo.getMembersWithUser(groupId);

      _members = rows
          .map((m) => _MemberRow(
        userId: m['user_id'] as int,
        displayName: (m['display_name'] as String?)?.trim().isNotEmpty == true
            ? (m['display_name'] as String)
            : (m['email'] as String? ?? 'Utilisateur'),
        email: m['email'] as String? ?? '',
        role: m['role'] as String,
        addedAt: DateTime.fromMillisecondsSinceEpoch(m['added_at'] as int),
      ))
          .toList();

      // current user owner?
      _currentIsOwner = _members.any(
              (mm) => mm.userId == _currentUserId && (mm.role.toLowerCase() == 'owner'));

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validateEmailList(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final emails = value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final emailRegex = RegExp(r'^[\w\.\-+]+@([\w\-]+\.)+[\w\-]{2,}$');
    final invalids = <String>[];
    for (final e in emails) {
      if (!emailRegex.hasMatch(e)) invalids.add(e);
    }
    if (invalids.isNotEmpty) {
      return 'Emails invalides: ${invalids.join(", ")}';
    }
    return null;
  }

  Future<void> _inviteByEmail() async {
    if (!(_inviteFormKey.currentState?.validate() ?? false)) return;

    final raw = _inviteController.text;
    final emails = raw
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
    if (emails.isEmpty) return;

    setState(() => _inviting = true);
    try {
      final groupId = int.parse(widget.group['id'] as String);
      final notFound = <String>[];

      for (final email in emails) {
        try {
          await _repo.addMemberByEmail(groupId: groupId, email: email);
        } catch (_) {
          notFound.add(email);
        }
      }

      if (!mounted) return;
      if (notFound.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitations envoyées')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Introuvables: ${notFound.join(", ")}')),
        );
      }
      _inviteController.clear();
      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      if (mounted) setState(() => _inviting = false);
    }
  }

  Future<void> _removeMember(_MemberRow m) async {
    if (!_currentIsOwner) return;
    if (m.role.toLowerCase() == 'owner') return;

    final groupId = int.parse(widget.group['id'] as String);

    try {
      await _repo.removeMember(groupId, m.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${m.displayName} retiré du groupe')),
      );
      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  // --- Photo actions ---------------------------------------------------------

  Future<void> _changePhoto() async {
    if (!_currentIsOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seul le propriétaire peut changer la photo.')),
      );
      return;
    }

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2048,
    );
    if (picked == null) return;

    // Copy into app documents for a stable path
    final dir = await getApplicationDocumentsDirectory();
    final ext = p.extension(picked.path);
    final filename = 'group_${DateTime.now().millisecondsSinceEpoch}$ext';
    final savedPath = p.join(dir.path, filename);
    await File(picked.path).copy(savedPath);

    final groupId = int.parse(widget.group['id'] as String);
    await _repo.updateGroupImage(groupId, savedPath);

    if (!mounted) return;
    setState(() => _imagePath = savedPath);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo mise à jour')),
    );
  }

  Future<void> _removePhoto() async {
    if (!_currentIsOwner) return;
    final groupId = int.parse(widget.group['id'] as String);
    await _repo.updateGroupImage(groupId, null);

    if (!mounted) return;
    setState(() => _imagePath = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo supprimée')),
    );
  }

  // --- Delete group (owner only) --------------------------------------------

  Future<void> _confirmAndDeleteGroup() async {
    if (!_currentIsOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seul le propriétaire peut supprimer le groupe.')),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le groupe ?'),
        content: const Text(
          'Cette action est irréversible. Tous les membres seront retirés et les données du groupe seront supprimées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final groupId = int.parse(widget.group['id'] as String);
      await _repo.deleteGroup(groupId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Groupe supprimé')),
      );
      // Pop back to list and signal deletion so caller can refresh
      Navigator.pop(context, 'deleted');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.group['name'] as String? ?? 'Groupe';
    final desc = widget.group['description'] as String? ?? '';
    final start = widget.group['startDate'] as DateTime?;
    final end = widget.group['endDate'] as DateTime?;
    final isActive = widget.group['isActive'] as bool? ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case 'change_photo':
                  await _changePhoto();
                  break;
                case 'remove_photo':
                  await _removePhoto();
                  break;
                case 'delete_group':
                  await _confirmAndDeleteGroup();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'change_photo',
                enabled: _currentIsOwner,
                child: const ListTile(
                  leading: Icon(Icons.photo_library_outlined),
                  title: Text('Changer la photo'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'remove_photo',
                enabled: _currentIsOwner && _imagePath != null,
                child: const ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Supprimer la photo'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete_group',
                enabled: _currentIsOwner,
                child: const ListTile(
                  leading: Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor),
                  title: Text(
                    'Supprimer le groupe',
                    style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600),
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeaderCard(name, desc, start, end, isActive),
            const SizedBox(height: 16),
            _buildMembersCard(),
            const SizedBox(height: 16),
            _buildInviteCard(),
          ],
        ),
      ),
    );
  }

  // --- UI Blocks -------------------------------------------------------------

  Widget _buildHeaderCard(
      String name, String desc, DateTime? start, DateTime? end, bool isActive) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image / gradient
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_imagePath != null &&
                    _imagePath!.isNotEmpty &&
                    File(_imagePath!).existsSync())
                  Image.file(File(_imagePath!), fit: BoxFit.cover)
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                Container(color: Colors.black.withOpacity(0.2)),
                const Center(
                  child: Icon(Icons.travel_explore, size: 56, color: Colors.white),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Actif' : 'Terminé',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              if (desc.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    _formatDates(start, end),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (_currentIsOwner) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _changePhoto,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Changer la photo'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _imagePath == null ? null : _removePhoto,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Supprimer'),
                    ),
                  ],
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Membres', style: AppTheme.headingSmall),
          const SizedBox(height: 12),
          if (_members.isEmpty)
            const Text(
              'Aucun membre pour le moment.',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            )
          else
            ..._members.map((m) => _memberTile(m)).toList(),
        ]),
      ),
    );
  }

  Widget _memberTile(_MemberRow m) {
    final initials = _initials(m.displayName);
    final canRemove =
        _currentIsOwner && m.userId != _currentUserId && m.role.toLowerCase() != 'owner';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        child: Text(initials, style: const TextStyle(color: AppTheme.primaryColor)),
      ),
      title: Text(
        m.displayName,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimaryColor,
        ),
      ),
      subtitle: Text(
        m.email,
        style: const TextStyle(color: AppTheme.textSecondaryColor),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: m.role.toLowerCase() == 'owner'
                  ? AppTheme.secondaryColor.withOpacity(0.15)
                  : AppTheme.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              m.role.toLowerCase() == 'owner' ? 'Propriétaire' : 'Membre',
              style: TextStyle(
                fontSize: 12,
                color: m.role.toLowerCase() == 'owner'
                    ? AppTheme.secondaryColor
                    : AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (canRemove) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.person_remove_alt_1_outlined),
              tooltip: 'Retirer',
              onPressed: () => _removeMember(m),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInviteCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Inviter des membres', style: AppTheme.headingSmall),
          const SizedBox(height: 12),
          Form(
            key: _inviteFormKey,
            child: TextFormField(
              controller: _inviteController,
              decoration: const InputDecoration(
                labelText: 'Email(s)',
                hintText: 'ami@example.com, autre@example.com',
                prefixIcon: Icon(Icons.email),
              ),
              validator: _validateEmailList,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _inviting ? null : _inviteByEmail,
                  icon: _inviting
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Icon(Icons.person_add_alt_1),
                  label: const Text('Inviter'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Séparez plusieurs emails par des virgules. Les utilisateurs doivent déjà avoir un compte.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
          ),
        ]),
      ),
    );
  }

  // --- Utils ----------------------------------------------------------------

  String _formatDates(DateTime? start, DateTime? end) {
    if (start == null && end == null) return 'Dates non définies';
    if (start != null && end == null) return _formatDate(start);
    if (start == null && end != null) return _formatDate(end);
    return '${_formatDate(start!)} - ${_formatDate(end!)}';
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

class _MemberRow {
  final int userId;
  final String displayName;
  final String email;
  final String role;
  final DateTime addedAt;

  _MemberRow({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.role,
    required this.addedAt,
  });
}
