import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:social_share/social_share.dart';  // ← Ajouter
import '../../theme/app_theme.dart';
import '../../models/journal_entry.dart';
import '../../services/database_service.dart';
import '../../widgets/comments_widget.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final ImagePicker _picker = ImagePicker();
  List<JournalEntry> _journalEntries = [];
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  List<JournalEntry> _filteredEntries = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  // Fonction pour charger les entrées depuis SQLite
  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final entries = await _databaseService.getAllEntries();
      setState(() {
        _journalEntries = entries;
        _filteredEntries = entries; // Initialiser la liste filtrée
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Fonction de recherche
  void _searchEntries() {
    showSearch(
      context: context,
      delegate: JournalSearchDelegate(_journalEntries, _onSearchResults),
    );
  }

  void _onSearchResults(List<JournalEntry> results) {
    setState(() {
      _filteredEntries = results;
    });
  }

  // Fonction d'export du journal
  void _exportJournal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.download, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Exporter mon carnet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Options d'export
            ListTile(
              leading: Icon(Icons.text_snippet, color: AppTheme.primaryColor),
              title: const Text('Export texte complet'),
              subtitle: const Text('Toutes les entrées en format texte'),
              onTap: () => _exportAsText(),
            ),
            
            ListTile(
              leading: Icon(Icons.picture_as_pdf, color: AppTheme.primaryColor),
              title: const Text('Export PDF'),
              subtitle: const Text('Génération d\'un PDF du carnet'),
              onTap: () => _exportAsPDF(),
            ),
            
            ListTile(
              leading: Icon(Icons.backup, color: AppTheme.primaryColor),
              title: const Text('Sauvegarde complète'),
              subtitle: const Text('Données + photos en archive'),
              onTap: () => _exportComplete(),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _exportAsText() async {
    Navigator.pop(context);
    
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = 'mon_carnet_voyage_${DateTime.now().millisecondsSinceEpoch}.txt';
      final String filePath = path.join(tempDir.path, fileName);
      
      String exportContent = '''
🌍 MON CARNET DE VOYAGE 🌍
========================================

Exporté le: ${DateTime.now().toString()}
Nombre d'entrées: ${_journalEntries.length}
Total photos: ${_getTotalPhotos()}
Total likes: ${_getTotalLikes()}

========================================

''';

      for (int i = 0; i < _journalEntries.length; i++) {
        final entry = _journalEntries[i];
        exportContent += '''
ENTRÉE ${i + 1}
----------------------------------------
Titre: ${entry.title}
Date: ${_formatDateTime(entry.date)}
Lieu: ${entry.location}
Humeur: ${_getMoodText(entry.mood)}
Type: ${_getTypeText(entry.type)}

Contenu:
${entry.content}

Photos: ${entry.photos.length}
Likes: ${entry.likes}
Commentaires: ${entry.comments}

----------------------------------------

''';
      }

      exportContent += '''
========================================
Fin du carnet - ${_journalEntries.length} entrées exportées
''';

      final File file = File(filePath);
      await file.writeAsString(exportContent);

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Mon Carnet de Voyage',
        text: 'Voici l\'export complet de mon carnet de voyage !',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📤 Carnet exporté avec succès !'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'export: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportAsPDF() async {
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('Génération du PDF en cours...'),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        duration: const Duration(seconds: 3),
      ),
    );

    // Simuler la génération PDF
    await Future.delayed(const Duration(seconds: 2));
    
    // Pour l'instant, on fait un export texte formaté
    await _exportAsText();
  }

  Future<void> _exportComplete() async {
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚧 Fonctionnalité en développement'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carnet de Voyage'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _searchEntries,
            tooltip: 'Rechercher',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEntries,
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportJournal,
            tooltip: 'Exporter',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistiques
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.8),
                        AppTheme.secondaryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.book,
                          label: 'Entrées',
                          value: '${_filteredEntries.length}', // Utiliser _filteredEntries
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.photo_camera,
                          label: 'Photos',
                          value: '${_getTotalPhotos()}',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.favorite,
                          label: 'Likes',
                          value: '${_getTotalLikes()}',
                        ),
                      ),
                    ],
                  ),
                ),

                // Timeline
                Expanded(
                  child: _filteredEntries.isEmpty // Utiliser _filteredEntries
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Aucune entrée dans votre carnet',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Créez votre première entrée !',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredEntries.length, // Utiliser _filteredEntries
                          itemBuilder: (context, index) {
                            final entry = _filteredEntries[index]; // Utiliser _filteredEntries
                            return _buildJournalEntry(entry, index);
                          },
                        ),
                ),

                // Bouton nouvelle entrée
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addJournalEntry,
                      icon: const Icon(Icons.add),
                      label: const Text('Nouvelle entrée'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildJournalEntry(JournalEntry entry, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getMoodColor(entry.mood),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getEntryTypeIcon(entry.type),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              if (index < _journalEntries.length - 1)
                Container(
                  width: 2,
                  height: 60,
                  color: Colors.grey.shade300,
                ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Entry content
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Par ${entry.author} • ${_formatDateTime(entry.date)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _getMoodIcon(entry.mood),
                          color: _getMoodColor(entry.mood),
                          size: 24,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Location
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            entry.location,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Content
                    Text(
                      entry.content,
                      style: const TextStyle(fontSize: 16),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Photos preview
                    if (entry.photos.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: entry.photos.length,
                          itemBuilder: (context, photoIndex) {
                            final photoPath = entry.photos[photoIndex];
                            return Container(
                              margin: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () => _showFullImage(photoPath),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _buildImageWidget(photoPath),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    
                    const SizedBox(height: 12),
                    
                    // Actions avec Wrap pour éviter l'overflow
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Groupe likes/commentaires
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.favorite_outline, size: 20),
                              onPressed: () => _likeEntry(entry.id!),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            Text('${entry.likes}', style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.comment_outlined, size: 20),
                              onPressed: () => _showComments(entry),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            Text('${entry.comments}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        
                        // Groupe actions
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.share, size: 18),
                              onPressed: () => _shareEntry(entry),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              tooltip: 'Partager',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () => _deleteEntry(entry.id!),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              tooltip: 'Supprimer',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addJournalEntry() {
    _showAddEntryDialog();
  }

  void _showAddEntryDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final locationController = TextEditingController();
    String selectedMood = 'happy';
    String selectedType = 'text';
    List<String> selectedImages = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.edit_note, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '✍️ Nouvelle entrée',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Contenu scrollable
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: 'Titre *',
                            hintText: 'Ex: Découverte de Montmartre',
                            prefixIcon: Icon(Icons.title, color: AppTheme.primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Contenu
                        TextField(
                          controller: contentController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Contenu *',
                            hintText: 'Décrivez votre expérience...',
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 40),
                              child: Icon(Icons.description, color: AppTheme.primaryColor),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Localisation
                        TextField(
                          controller: locationController,
                          decoration: InputDecoration(
                            labelText: 'Lieu',
                            hintText: 'Ex: Tour Eiffel, Paris',
                            prefixIcon: Icon(Icons.location_on, color: AppTheme.primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Section Photos
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header photos
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.photo_library, color: AppTheme.primaryColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Photos (${selectedImages.length})',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                                      onPressed: () => _pickImage(ImageSource.camera, selectedImages, setDialogState),
                                      tooltip: 'Prendre une photo',
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(
                                        minWidth: 40,
                                        minHeight: 40,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.photo_library, color: AppTheme.primaryColor),
                                      onPressed: () => _pickImage(ImageSource.gallery, selectedImages, setDialogState),
                                      tooltip: 'Choisir depuis la galerie',
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(
                                        minWidth: 40,
                                        minHeight: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Aperçu des images
                              if (selectedImages.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  child: SizedBox(
                                    height: 100,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: selectedImages.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          margin: const EdgeInsets.only(right: 12),
                                          child: Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.file(
                                                  File(selectedImages[index]),
                                                  width: 100,
                                                  height: 100,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setDialogState(() {
                                                      selectedImages.removeAt(index);
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: const Icon(
                                                      Icons.close, 
                                                      color: Colors.white, 
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Aucune photo ajoutée',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Type et Humeur
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedType,
                                decoration: InputDecoration(
                                  labelText: 'Type',
                                  prefixIcon: Icon(_getEntryTypeIcon(selectedType), color: AppTheme.primaryColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'text',
                                    child: Text('Journal'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'photo',
                                    child: Text('Photos'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'food',
                                    child: Text('Cuisine'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'activity',
                                    child: Text('Activité'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedType = value!;
                                  });
                                },
                                isExpanded: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedMood,
                                decoration: InputDecoration(
                                  labelText: 'Humeur',
                                  prefixIcon: Icon(_getMoodIcon(selectedMood), color: _getMoodColor(selectedMood)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'happy',
                                    child: Text('Heureux'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'excited',
                                    child: Text('Excité'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'amazed',
                                    child: Text('Émerveillé'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'sad',
                                    child: Text('Triste'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'neutral',
                                    child: Text('Neutre'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedMood = value!;
                                  });
                                },
                                isExpanded: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Boutons d'action
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                      ),
                      child: const Text('Annuler'),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Ajouter'),
                      onPressed: () {
                        if (_validateForm(titleController.text, contentController.text)) {
                          _createNewEntry(
                            titleController.text.trim(),
                            contentController.text.trim(),
                            selectedMood,
                            locationController.text.trim().isNotEmpty 
                              ? locationController.text.trim() 
                              : 'Localisation non spécifiée',
                            selectedType,
                            selectedImages,
                          );
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Veuillez remplir le titre et le contenu'),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ),
      );
  }

  // Fonction pour choisir une image
  Future<void> _pickImage(ImageSource source, List<String> selectedImages, StateSetter setDialogState) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        // Copier l'image dans le dossier media
        final String savedImagePath = await _saveImageToMedia(image.path);
        
        setDialogState(() {
          selectedImages.add(savedImagePath);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Photo ajoutée ! (${selectedImages.length} photos)'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout de la photo: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Fonction pour sauvegarder l'image dans le dossier media
  Future<String> _saveImageToMedia(String originalPath) async {
    try {
      // Utiliser le répertoire des documents de l'application
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String mediaDir = path.join(appDocDir.path, 'media');
      final Directory mediaDirectory = Directory(mediaDir);
      
      if (!await mediaDirectory.exists()) {
        await mediaDirectory.create(recursive: true);
      }

      // Générer un nom unique pour l'image
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = path.extension(originalPath);
      final String fileName = 'journal_${timestamp}${extension}';
      final String newPath = path.join(mediaDir, fileName);

      // Copier le fichier
      final File originalFile = File(originalPath);
      final File newFile = await originalFile.copy(newPath);

      return newFile.path;
    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'image: $e');
      return originalPath;
    }
  }

  Widget _buildImageWidget(String imagePath) {
    // Vérifier si c'est un chemin absolu (fichier sauvegardé)
    if (File(imagePath).existsSync()) {
      return Image.file(
        File(imagePath),
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 100,
            height: 100,
            color: Colors.grey.shade300,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    } else {
      // Image par défaut si le fichier n'existe pas
      return Container(
        width: 100,
        height: 100,
        color: Colors.grey.shade300,
        child: const Icon(
          Icons.image,
          color: Colors.grey,
          size: 32,
        ),
      );
    }
  }

  void _showFullImage(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: File(imagePath).existsSync()
                    ? Image.file(
                        File(imagePath),
                        fit: BoxFit.contain,
                      )
                    : Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                            size: 64,
                          ),
                        ),
                      ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fonctions SQLite
  Future<void> _likeEntry(int entryId) async {
    try {
      await _databaseService.likeEntry(entryId);
      await _loadEntries();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteEntry(int entryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'entrée'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette entrée ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteEntry(entryId);
        await _loadEntries();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entrée supprimée'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showComments(JournalEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => CommentsWidget(entry: entry),
      ),
    );
  }

  void _shareEntry(JournalEntry entry) {
    _showShareOptions(entry);
  }

  void _showShareOptions(JournalEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Header
            Text(
              'Partager votre voyage',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              entry.title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 24),
            
            // Options de partage
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Première ligne - Réseaux sociaux
                  Row(
                    children: [
                      Expanded(
                        child: _buildShareOption(
                          icon: Icons.camera_alt,
                          label: 'Instagram',
                          color: Colors.purple,
                          onTap: () => _shareToInstagram(entry),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildShareOption(
                          icon: Icons.facebook,
                          label: 'Facebook',
                          color: Colors.blue,
                          onTap: () => _shareToFacebook(entry),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildShareOption(
                          icon: Icons.alternate_email,
                          label: 'Twitter',
                          color: Colors.lightBlue,
                          onTap: () => _shareToTwitter(entry),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Deuxième ligne - Apps natives
                  Row(
                    children: [
                      Expanded(
                        child: _buildShareOption(
                          icon: Icons.chat,
                          label: 'WhatsApp',
                          color: Colors.green,
                          onTap: () => _shareToWhatsApp(entry),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildShareOption(
                          icon: Icons.message,
                          label: 'Messages',
                          color: Colors.blue,
                          onTap: () => _shareToMessages(entry),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildShareOption(
                          icon: Icons.more_horiz,
                          label: 'Plus',
                          color: AppTheme.primaryColor,
                          onTap: () => _shareToOthers(entry),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Fonctions de partage spécifiques
  Future<void> _shareToInstagram(JournalEntry entry) async {
    try {
      if (entry.photos.isNotEmpty && File(entry.photos.first).existsSync()) {
        await SocialShare.shareInstagramStory(
          appId: "1341322244146516", // ✅ Ajouter l'appId pour Instagram aussi
          imagePath: entry.photos.first,
          backgroundTopColor: "#ffffff",
          backgroundBottomColor: "#000000",
          attributionURL: "https://monapp.com",
        );
        _showShareSuccess('Partagé sur Instagram Stories');
      } else {
        _showShareError('Aucune photo disponible pour Instagram');
      }
    } catch (e) {
      _showShareError('Instagram non disponible');
    }
  }

  Future<void> _shareToFacebook(JournalEntry entry) async {
    try {
      if (entry.photos.isNotEmpty && File(entry.photos.first).existsSync()) {
        await SocialShare.shareFacebookStory(
          appId: "1341322244146516", // ✅ Votre App ID Facebook
          imagePath: entry.photos.first,
          backgroundTopColor: "#ffffff",
          backgroundBottomColor: "#000000",
          attributionURL: "https://monapp.com",
        );
        _showShareSuccess('Partagé sur Facebook Stories');
      } else {
        // Si pas de photo, partage texte via lien
        final content = _createShareContent(entry);
        final encodedContent = Uri.encodeComponent(content);
        await launchUrl(
          Uri.parse("https://www.facebook.com/sharer/sharer.php?quote=$encodedContent"),
        );
        _showShareSuccess('Ouverture de Facebook');
      }
    } catch (e) {
      _showShareError('Facebook non disponible');
    }
  }

  Future<void> _shareToTwitter(JournalEntry entry) async {
    try {
      final content = _createShareContent(entry);
      // Limiter à 280 caractères pour Twitter
      String tweetContent = content.length > 250 
          ? '${content.substring(0, 250)}...' 
          : content;
      
      final encodedTweet = Uri.encodeComponent(tweetContent);
      await launchUrl(Uri.parse("https://twitter.com/intent/tweet?text=$encodedTweet"));
      _showShareSuccess('Ouverture de Twitter');
    } catch (e) {
      _showShareError('Twitter non disponible');
    }
  }

  Future<void> _shareToWhatsApp(JournalEntry entry) async {
    try {
      final content = _createShareContent(entry);
      final encodedContent = Uri.encodeComponent(content);
      await launchUrl(Uri.parse("https://wa.me/?text=$encodedContent"));
      _showShareSuccess('Ouverture de WhatsApp');
    } catch (e) {
      // Fallback vers partage natif
      await _shareToOthers(entry);
    }
  }

  Future<void> _shareToMessages(JournalEntry entry) async {
    try {
      final content = _createShareContent(entry);
      final encodedContent = Uri.encodeComponent(content);
      await launchUrl(Uri.parse("sms:?body=$encodedContent"));
      _showShareSuccess('Ouverture de Messages');
    } catch (e) {
      // Fallback vers partage natif
      await _shareToOthers(entry);
    }
  }

  Future<void> _shareToOthers(JournalEntry entry) async {
    try {
      final content = _createShareContent(entry);
      
      if (entry.photos.isNotEmpty) {
        List<XFile> validPhotos = [];
        for (String photoPath in entry.photos) {
          if (File(photoPath).existsSync()) {
            validPhotos.add(XFile(photoPath));
          }
        }
        
        if (validPhotos.isNotEmpty) {
          await Share.shareXFiles(
            validPhotos,
            text: content,
            subject: 'Mon voyage: ${entry.title}',
          );
        } else {
          await Share.share(content, subject: 'Mon voyage: ${entry.title}');
        }
      } else {
        await Share.share(content, subject: 'Mon voyage: ${entry.title}');
      }
    } catch (e) {
      _showShareError('Erreur lors du partage');
    }
  }

  String _createShareContent(JournalEntry entry) {
    return '''🌍 ${entry.title}

📍 ${entry.location}
📅 ${_formatDateTime(entry.date)}
😊 ${_getMoodText(entry.mood)}

${entry.content}

${entry.photos.isNotEmpty ? '📷 ${entry.photos.length} photo(s)' : ''}

--- Partagé depuis mon Carnet de Voyage ---''';
  }

  void _showShareSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showShareError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Fonctions utilitaires manquantes
  int _getTotalPhotos() {
    int total = 0;
    for (var entry in _journalEntries) {
      total += entry.photos.length;
    }
    return total;
  }

  int _getTotalLikes() {
    int total = 0;
    for (var entry in _journalEntries) {
      total += entry.likes;
    }
    return total;
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _getMoodText(String? mood) {
    switch (mood) {
      case 'happy':
        return 'Heureux 😊';
      case 'excited':
        return 'Excité 🎉';
      case 'amazed':
        return 'Émerveillé 🤩';
      case 'sad':
        return 'Triste 😢';
      case 'neutral':
        return 'Neutre 😐';
      default:
        return 'Non spécifié';
    }
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'text':
        return 'Journal';
      case 'photo':
        return 'Photos';
      case 'food':
        return 'Cuisine';
      case 'activity':
        return 'Activité';
      default:
        return 'Autre';
    }
  }

  Color _getMoodColor(String? mood) {
    switch (mood) {
      case 'happy':
        return Colors.green;
      case 'excited':
        return Colors.orange;
      case 'amazed':
        return Colors.purple;
      case 'sad':
        return Colors.blueGrey;
      case 'neutral':
        return Colors.grey;
      default:
        return Colors.grey.shade400;
    }
  }

  IconData _getMoodIcon(String? mood) {
    switch (mood) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'excited':
        return Icons.celebration;
      case 'amazed':
        return Icons.star; // ✅ Remplacer star_eyes par star
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'neutral':
        return Icons.sentiment_neutral;
      default:
        return Icons.sentiment_neutral;
    }
  }

  IconData _getEntryTypeIcon(String type) {
    switch (type) {
      case 'text':
        return Icons.article;
      case 'photo':
        return Icons.photo_camera;
      case 'food':
        return Icons.restaurant;
      case 'activity':
        return Icons.directions_run;
      default:
        return Icons.note;
    }
  }

  bool _validateForm(String title, String content) {
    return title.trim().isNotEmpty && content.trim().isNotEmpty;
  }

  Future<void> _createNewEntry(
    String title,
    String content,
    String mood,
    String location,
    String type,
    List<String> photos,
  ) async {
    try {
      final newEntry = JournalEntry(
        title: title,
        content: content,
        date: DateTime.now(),
        mood: mood,
        location: location,
        type: type,
        photos: photos,
        author: 'Vous', // ou récupérer le vrai nom de l'utilisateur
        likes: 0,
        comments: 0,
      );

      await _databaseService.insertEntry(newEntry);
      await _loadEntries();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Entrée "${title}" ajoutée !'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// Classe pour la recherche
class JournalSearchDelegate extends SearchDelegate<String> {
  final List<JournalEntry> entries;
  final Function(List<JournalEntry>) onSearchResults;

  JournalSearchDelegate(this.entries, this.onSearchResults);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          onSearchResults(entries);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
        onSearchResults(entries);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = entries.where((entry) {
      return entry.title.toLowerCase().contains(query.toLowerCase()) ||
             entry.content.toLowerCase().contains(query.toLowerCase()) ||
             entry.location.toLowerCase().contains(query.toLowerCase());
    }).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      onSearchResults(results);
    });

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final entry = results[index];
        return ListTile(
          leading: Icon(
            _getEntryTypeIcon(entry.type),
            color: AppTheme.primaryColor,
          ),
          title: Text(entry.title),
          subtitle: Text(
            '${entry.location} • ${entry.content.substring(0, entry.content.length > 50 ? 50 : entry.content.length)}...',
          ),
          onTap: () {
            close(context, entry.title);
          },
        );
      },
    );
  }

  IconData _getEntryTypeIcon(String type) {
    switch (type) {
      case 'text':
        return Icons.article;
      case 'photo':
        return Icons.photo;
      case 'food':
        return Icons.restaurant;
      case 'activity':
        return Icons.directions_run;
      default:
        return Icons.note;
    }
  }
}