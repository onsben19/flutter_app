import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../../theme/app_theme.dart';
import '../../models/journal_entry.dart';
import '../../services/database_service.dart';
import '../../widgets/app_user_icon_button.dart';

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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppUserIconButton(), // 👈 user icon on the left
        title: const Text('Carnet de Voyage'),
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
                          value: '${_journalEntries.length}',
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
                  child: _journalEntries.isEmpty
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
                          itemCount: _journalEntries.length,
                          itemBuilder: (context, index) {
                            final entry = _journalEntries[index];
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
                    
                    // Actions
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.favorite_outline),
                          onPressed: () => _likeEntry(entry.id!),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                        Text('${entry.likes}'),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.comment_outlined),
                          onPressed: () => _showComments(entry),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                        Text('${entry.comments}'),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteEntry(entry.id!),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () => _shareEntry(entry),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo ajoutée ! (${selectedImages.length} photos)'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ajout de la photo: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Fonction pour sauvegarder l'image dans le dossier media
  Future<String> _saveImageToMedia(String originalPath) async {
    try {
      // Créer le dossier media s'il n'existe pas
      final String mediaDir = path.join(Directory.current.path, 'lib', 'media');
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
      // En cas d'erreur, retourner le chemin original
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrée supprimée'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commentaires - ${entry.title}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Expanded(
              child: Center(
                child: Text(
                  'Aucun commentaire pour le moment',
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                ),
              ),
            ),
            const Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Ajouter un commentaire...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.send),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _shareEntry(JournalEntry entry) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partage de "${entry.title}"'),
      ),
    );
  }

  void _searchEntries() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recherche dans le journal à implémenter'),
      ),
    );
  }

  void _exportJournal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exporter le carnet'),
        content: const Text('Choisissez le format d\'export :'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export PDF en cours...'),
                ),
              );
            },
            child: const Text('PDF'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export Album photo en cours...'),
                ),
              );
            },
            child: const Text('Album'),
          ),
        ],
      ),
    );
  }

  // Fonctions utilitaires
  int _getTotalPhotos() {
    return _journalEntries
        .map((entry) => entry.photos.length)
        .fold(0, (sum, count) => sum + count);
  }

  int _getTotalLikes() {
    return _journalEntries
        .map((entry) => entry.likes)
        .fold(0, (sum, likes) => sum + likes);
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
  
  Widget _buildStatItem({required IconData icon, required String label, required String value}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
  
  IconData _getMoodIcon(String? mood) {
    switch (mood) {
      case 'happy':
        return Icons.sentiment_satisfied;
      case 'excited':
        return Icons.emoji_events;
      case 'amazed':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'neutral':
        return Icons.sentiment_neutral;
      default:
        return Icons.sentiment_satisfied;
    }
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

  // Fonction de validation du formulaire
  bool _validateForm(String title, String content) {
    return title.trim().isNotEmpty && content.trim().isNotEmpty;
  }

  // Fonction pour créer une nouvelle entrée avec SQLite
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
        author: 'Moi',
        type: type,
        location: location,
        mood: mood,
        photos: photos,
      );

      await _databaseService.insertEntry(newEntry);
      await _loadEntries(); // Recharger les entrées

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Entrée "${title}" ajoutée avec succès !'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
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