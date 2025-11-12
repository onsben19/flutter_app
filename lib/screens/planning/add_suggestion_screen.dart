import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AddSuggestionScreen extends StatefulWidget {
  const AddSuggestionScreen({super.key});

  @override
  State<AddSuggestionScreen> createState() => _AddSuggestionScreenState();
}

class _AddSuggestionScreenState extends State<AddSuggestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _durationController = TextEditingController();
  
  String _selectedCategory = 'Monument';
  final List<String> _categories = [
    'Monument',
    'Musée',
    'Restaurant',
    'Activité',
    'Hébergement',
    'Transport',
    'Shopping',
    'Nature',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Suggestion'),
        actions: [
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _saveSuggestion();
              }
            },
            child: const Text(
              'Publier',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photo de suggestion
            Center(
              child: GestureDetector(
                onTap: () {
                  // TODO: Sélectionner une image
                },
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        color: AppTheme.primaryColor,
                        size: 48,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Ajouter une photo',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Titre
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre *',
                hintText: 'Ex: Tour Eiffel',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir un titre';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Catégorie
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Catégorie *',
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Décrivez cette suggestion...',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir une description';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Coût et durée
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _costController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Coût (€)',
                      hintText: '0',
                      prefixIcon: Icon(Icons.euro),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return 'Montant invalide';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Durée',
                      hintText: 'Ex: 2h30',
                      prefixIcon: Icon(Icons.access_time),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Section informations supplémentaires
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations supplémentaires',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Adresse
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Adresse',
                        hintText: 'Champ de Mars, 5 Av. Anatole France, 75007 Paris',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Site web
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Site web',
                        hintText: 'https://www.example.com',
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Horaires
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Horaires',
                        hintText: '9h00 - 18h00',
                        prefixIcon: Icon(Icons.schedule),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Conseils
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outlined,
                        color: AppTheme.secondaryColor,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Conseils pour une bonne suggestion',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Ajoutez une photo attractive\n'
                    '• Soyez précis dans la description\n'
                    '• Indiquez le coût approximatif\n'
                    '• Mentionnez la durée de visite',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _saveSuggestion() {
    // TODO: Sauvegarder la suggestion
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Suggestion ajoutée avec succès !'),
        backgroundColor: Colors.green,
      ),
    );
    
    Navigator.pop(context);
  }
}