import 'package:flutter/material.dart';
import 'dart:io';
import '../theme/app_theme.dart';

class SuggestionCard extends StatelessWidget {
  final Map<String, dynamic> suggestion;
  final VoidCallback onVote;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SuggestionCard({
    super.key,
    required this.suggestion,
    required this.onVote,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final int votes = (suggestion['votes'] as int?) ?? 0;
    final int totalMembers = (suggestion['totalMembers'] as int?) ?? 0;
    final bool isVoted = (suggestion['isVoted'] as bool?) ?? false;
    final int votePercentage = totalMembers > 0
        ? ((votes / totalMembers) * 100).round()
        : 0;
    final bool isApproved = totalMembers > 0
        ? votes >= (totalMembers * 0.6).ceil()
        : false; // avoid division by zero

    final String imageUrl = (suggestion['imageUrl'] as String?)?.trim() ?? '';
    ImageProvider? bgImage;
    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http') || imageUrl.startsWith('data:')) {
        bgImage = NetworkImage(imageUrl);
      } else {
        try {
          if (File(imageUrl).existsSync()) {
            bgImage = FileImage(File(imageUrl));
          }
        } catch (_) {
          // ignore invalid file path
        }
      }
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image de couverture
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: bgImage == null
                  ? LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.8),
                        AppTheme.secondaryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              image: bgImage != null
                  ? DecorationImage(
                      image: bgImage,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                // Overlay to improve readability
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.25),
                      ],
                    ),
                  ),
                ),
                if (bgImage == null)
                  const Center(
                    child: Icon(
                      Icons.place,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                
                // Badge de catégorie
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      suggestion['category'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                
                // Badge d'approbation
                if (isApproved)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 28,
                    ),
                  ),
              ],
            ),
          ),
          
          // Contenu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre et coût
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        suggestion['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${suggestion['cost']}€',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Description
                Text(
                  suggestion['description'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Informations
                Row(
                  children: [
                    if ((suggestion['tripDay'] ?? 0) is int && (suggestion['tripDay'] ?? 0) > 0) ...[
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Jour ${suggestion['tripDay']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if ((suggestion['tripTime'] as String?)?.isNotEmpty == true) ...[
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        suggestion['tripTime'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      suggestion['duration'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Par ${suggestion['suggestedBy']}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Barre de progression des votes
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Votes: $votes/$totalMembers',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$votePercentage%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isApproved ? Colors.green : AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: totalMembers > 0
                          ? (votes / totalMembers).clamp(0.0, 1.0).toDouble()
                          : 0.0,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isApproved ? Colors.green : AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onVote,
                        icon: Icon(
                          isVoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                          size: 18,
                        ),
                        label: Text(isVoted ? 'Voté' : 'Voter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isVoted 
                              ? AppTheme.primaryColor 
                              : Colors.grey.shade200,
                          foregroundColor: isVoted 
                              ? Colors.white 
                              : AppTheme.textPrimaryColor,
                          elevation: isVoted ? 2 : 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Modifier',
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outlined),
                      tooltip: 'Supprimer',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
