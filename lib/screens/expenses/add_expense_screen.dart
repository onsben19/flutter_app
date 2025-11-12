import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/expense.dart';
import '../../services/expense_service.dart';
import '../../providers/expense_providers.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String groupId;
  final List<String> groupMembers; // Liste des IDs des membres
  final Map<String, String> memberNames; // Map ID -> Nom
  final Expense? expense; // Si fourni, on est en mode édition

  const AddExpenseScreen({
    super.key,
    required this.groupId,
    required this.groupMembers,
    required this.memberNames,
    this.expense,
  });

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Autre';
  DateTime _selectedDate = DateTime.now();
  String? _selectedPaidBy;
  List<String> _selectedParticipants = [];

  final List<String> _categories = [
    'Hébergement',
    'Restaurant',
    'Transport',
    'Activité',
    'Shopping',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      // Mode édition
      final expense = widget.expense!;
      _titleController.text = expense.title;
      _amountController.text = expense.amount.toStringAsFixed(2);
      _descriptionController.text = expense.description ?? '';
      _selectedCategory = expense.category;
      _selectedDate = expense.date;
      _selectedPaidBy = expense.paidBy;
      _selectedParticipants = List.from(expense.participants);
    } else {
      // Mode création - sélectionner tous les membres par défaut
      _selectedParticipants = List.from(widget.groupMembers);
      if (widget.groupMembers.isNotEmpty) {
        _selectedPaidBy = widget.groupMembers.first;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _toggleParticipant(String memberId) {
    setState(() {
      if (_selectedParticipants.contains(memberId)) {
        _selectedParticipants.remove(memberId);
      } else {
        _selectedParticipants.add(memberId);
      }
    });
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPaidBy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner qui a payé')),
      );
      return;
    }

    if (_selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner au moins un participant')),
      );
      return;
    }

    try {
      final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le montant doit être supérieur à 0')),
        );
        return;
      }

      final expense = Expense(
        id: widget.expense?.id,
        title: _titleController.text.trim(),
        amount: amount,
        category: _selectedCategory,
        date: _selectedDate,
        paidBy: _selectedPaidBy!,
        participants: _selectedParticipants,
        groupId: widget.groupId,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      final service = ref.read(expenseServiceProvider);

      if (widget.expense != null) {
        await service.updateExpense(expense);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dépense mise à jour avec succès')),
          );
        }
      } else {
        await service.createExpense(expense);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dépense créée avec succès')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense != null ? 'Modifier la dépense' : 'Nouvelle dépense'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Titre
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre *',
                hintText: 'Ex: Restaurant Le Procope',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer un titre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Montant
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Montant (€) *',
                hintText: '0.00',
                prefixIcon: Icon(Icons.euro),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer un montant';
                }
                final amount = double.tryParse(value.replaceAll(',', '.'));
                if (amount == null || amount <= 0) {
                  return 'Montant invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Catégorie
            DropdownButtonFormField<String>(
              value: _selectedCategory,
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
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Date
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date *',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payé par
            DropdownButtonFormField<String>(
              value: _selectedPaidBy,
              decoration: const InputDecoration(
                labelText: 'Payé par *',
                prefixIcon: Icon(Icons.person),
              ),
              items: widget.groupMembers.map((memberId) {
                return DropdownMenuItem(
                  value: memberId,
                  child: Text(widget.memberNames[memberId] ?? memberId),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPaidBy = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Participants
            const Text(
              'Participants *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.groupMembers.map((memberId) {
              final isSelected = _selectedParticipants.contains(memberId);
              return CheckboxListTile(
                title: Text(widget.memberNames[memberId] ?? memberId),
                value: isSelected,
                onChanged: (value) => _toggleParticipant(memberId),
                secondary: CircleAvatar(
                  backgroundColor: isSelected
                      ? AppTheme.primaryColor
                      : Colors.grey.shade300,
                  child: Icon(
                    Icons.person,
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                hintText: 'Ajoutez des détails...',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Aperçu du calcul
            if (_amountController.text.isNotEmpty &&
                _selectedParticipants.isNotEmpty)
              Card(
                color: AppTheme.primaryColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Répartition',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Part par personne: ${(double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0) / _selectedParticipants.length} €',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Bouton de sauvegarde
            ElevatedButton(
              onPressed: _saveExpense,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                widget.expense != null ? 'Mettre à jour' : 'Créer la dépense',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

