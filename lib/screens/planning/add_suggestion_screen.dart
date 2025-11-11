import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../models/planification.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';

class AddSuggestionScreen extends StatefulWidget {
  final Planification? initial;
  const AddSuggestionScreen({super.key, this.initial});

  @override
  State<AddSuggestionScreen> createState() => _AddSuggestionScreenState();
}

class _AddSuggestionScreenState extends State<AddSuggestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _durationController = TextEditingController();
  final _dayController = TextEditingController();
  final _timeController = TextEditingController();

  final List<String> _selectedImages = [];

  String _selectedCategory = 'Monument';
  // Use escaped Unicode to avoid encoding issues on different platforms
  final List<String> _categories = [
    'Monument',
    'Mus\u00E9e',
    'Restaurant',
    'Activit\u00E9',
    'H\u00E9bergement',
    'Transport',
    'Shopping',
    'Nature',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    if (p != null) {
      _titleController.text = p.title;
      _descriptionController.text = p.description;
      _costController.text = p.cost.toStringAsFixed(
          p.cost.truncateToDouble() == p.cost ? 0 : 2);
      _durationController.text = p.duration;
      _selectedCategory = p.category;
      _selectedImages.addAll(p.imageUrls);
      if (p.tripDay > 0) _dayController.text = p.tripDay.toString();
      if (p.tripTime.isNotEmpty) _timeController.text = p.tripTime;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _durationController.dispose();
    _dayController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null
            ? 'Nouvelle suggestion'
            : 'Modifier la suggestion'),
        actions: [
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await _saveSuggestion();
              }
            },
            child: Text(
              widget.initial == null ? 'Publier' : 'Enregistrer',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photos
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.photo_library),
                        const SizedBox(width: 8),
                        const Text('Photos', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Ajouter'),
                        ),
                      ],
                    ),
                    if (_selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            final path = _selectedImages[index];
                            return Container(
                              margin: const EdgeInsets.only(right: 12),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(path),
                                      width: 120,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedImages.removeAt(index)),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre *',
                hintText: 'Ex: Tour Eiffel',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Veuillez saisir un titre' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v ?? _selectedCategory),
              decoration: const InputDecoration(labelText: 'Cat\u00E9gorie *', prefixIcon: Icon(Icons.category)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'D\u00E9crivez cette suggestion...',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Veuillez saisir une description' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _costController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Co\u00FBt (\u20AC)',
                      hintText: '0',
                      prefixIcon: Icon(Icons.euro),
                    ),
                    validator: (v) {
                      if (v != null && v.isNotEmpty && double.tryParse(v) == null) return 'Montant invalide';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Dur\u00E9e',
                      hintText: 'Ex: 2h30',
                      prefixIcon: Icon(Icons.access_time),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dayController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jour du voyage',
                      hintText: 'Ex: 1',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _timeController,
                    readOnly: true,
                    onTap: () async {
                      final now = TimeOfDay.now();
                      final picked = await showTimePicker(context: context, initialTime: now);
                      if (picked != null) {
                        final text = picked.format(context);
                        // Normalize to HH:mm 24h if possible
                        final hh = picked.hour.toString().padLeft(2, '0');
                        final mm = picked.minute.toString().padLeft(2, '0');
                        _timeController.text = '$hh:$mm';
                        setState(() {});
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Heure',
                      hintText: 'Ex: 09:00',
                      prefixIcon: Icon(Icons.schedule),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSuggestion() async {
    try {
      final cost = double.tryParse(_costController.text.trim()) ?? 0.0;
      final isEdit = widget.initial != null;
      final base = widget.initial;
      final plan = (base ?? Planification(
              title: '',
              description: '',
              category: '',
              duration: '',
              cost: 0.0,
              suggestedBy: 'Moi'))
          .copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        duration: _durationController.text.trim(),
        cost: cost,
        imageUrls: List<String>.from(_selectedImages),
        tripDay: int.tryParse(_dayController.text.trim()) ?? (base?.tripDay ?? 0),
        tripTime: _timeController.text.trim(),
      );
      if (isEdit) {
        await DatabaseService().updatePlanification(plan);
      } else {
        await DatabaseService().insertPlanification(plan);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isEdit
            ? 'Suggestion mise à jour'
            : 'Suggestion ajout\u00E9e avec succ\u00E8s'),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickImages() async {
    final files = await openFiles(
      acceptedTypeGroups: [
        XTypeGroup(label: 'images', extensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'])
      ],
    );
    if (files.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(files.map((f) => f.path).whereType<String>());
      });
    }
  }
}
