import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../theme/app_theme.dart';
import '../../services/group_repository.dart';
import '../../services/session_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _membersController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;

  final _groupRepo = GroupRepository();

  // Image state
  final _picker = ImagePicker();
  String? _imagePath; // saved local path (copied into app docs)

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _membersController.dispose();
    super.dispose();
  }

  // --- Email list validator (comma-separated)
  String? _validateEmailList(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional field
    final emails = value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Basic yet solid email regex
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

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2048,
    );
    if (picked == null) return;

    // Copy to app documents so we keep a stable private path
    final dir = await getApplicationDocumentsDirectory();
    final ext = p.extension(picked.path);
    final filename = 'group_${DateTime.now().millisecondsSinceEpoch}$ext';
    final savedPath = p.join(dir.path, filename);

    await File(picked.path).copy(savedPath);

    setState(() {
      _imagePath = savedPath;
    });
  }

  Future<void> _onCreatePressed() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La date de fin doit être après la date de début.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final session = await SessionService.getLoggedInUser();
      if (session == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();

      final memberEmails = _membersController.text
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList();

      final (groupId, notFound) = await _groupRepo.createGroup(
        ownerId: session.id,
        name: name,
        description: description.isEmpty ? null : description,
        memberEmails: memberEmails,
        startDate: _startDate,
        endDate: _endDate,
        imagePath: _imagePath, // ⬅️ store image path in DB
      );

      if (!mounted) return;

      if (notFound.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Groupe créé avec succès')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Groupe créé (introuvables: ${notFound.join(", ")})')),
        );
      }

      // Return the id so caller can refresh list
      Navigator.pop(context, groupId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Groupe'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _onCreatePressed,
            child: _isSaving
                ? const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Text('Créer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photo de groupe (tap to pick)
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(color: primary.withOpacity(0.3), width: 2),
                    image: _imagePath != null
                        ? DecorationImage(
                      image: FileImage(File(_imagePath!)),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: _imagePath == null
                      ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, color: AppTheme.primaryColor, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Ajouter\nune photo',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.primaryColor, fontSize: 12),
                      ),
                    ],
                  )
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Nom du groupe
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom du groupe',
                hintText: 'Ex: Voyage à Paris',
                prefixIcon: Icon(Icons.group),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir un nom pour le groupe';
                }
                if (value.trim().length < 3) {
                  return 'Nom trop court (min 3 caractères)';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Décrivez votre voyage...',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),

            // Dates
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    label: 'Date de début',
                    date: _startDate,
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    label: 'Date de fin',
                    date: _endDate,
                    onTap: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Invitations
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Inviter des membres', style: AppTheme.headingSmall),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _membersController,
                      decoration: const InputDecoration(
                        labelText: 'Email des membres',
                        hintText: 'ami@example.com, autre@example.com',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: _validateEmailList,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Séparez les emails par des virgules. Les espaces et les items vides sont ignorés.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Partager le lien d'invitation
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Partager le lien'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Générer un code d'invitation
                            },
                            icon: const Icon(Icons.qr_code),
                            label: const Text('Code QR'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  date != null ? '${date.day}/${date.month}/${date.year}' : 'Sélectionner',
                  style: TextStyle(
                    fontSize: 16,
                    color: date != null ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? now)
          : (_endDate ?? _startDate ?? now),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }
}
