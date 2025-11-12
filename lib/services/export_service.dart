import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class ExportService {
  final ExpenseService _expenseService = ExpenseService();

  // Exporter en PDF
  Future<void> exportToPDF(
    List<Expense> expenses,
    Map<String, String> memberNames,
    String groupId,
  ) async {
    final pdf = pw.Document();
    final totalExpenses = _expenseService.getTotalExpenses(expenses);
    final totalsByCategory = _expenseService.getTotalByCategory(expenses);
    final balances = await _expenseService.calculateMemberBalances(
      expenses,
      memberNames,
    );
    final debts = _expenseService.calculateDebts(balances);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // En-tête
          pw.Header(
            level: 0,
            child: pw.Text(
              'Rapport des Dépenses',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),

          // Résumé
          pw.Text(
            'Résumé',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total des dépenses:'),
              pw.Text(
                '${totalExpenses.toStringAsFixed(2)} €',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Nombre de dépenses:'),
              pw.Text('${expenses.length}'),
            ],
          ),
          pw.SizedBox(height: 20),

          // Totaux par catégorie
          pw.Text(
            'Totaux par catégorie',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          ...totalsByCategory.entries.map((entry) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(entry.key),
                    pw.Text('${entry.value.toStringAsFixed(2)} €'),
                  ],
                ),
              )),
          pw.SizedBox(height: 20),

          // Soldes par membre
          pw.Text(
            'Soldes par membre',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          ...balances.values.map((balance) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(balance.memberName),
                    pw.Text(
                      '${balance.balance.toStringAsFixed(2)} €',
                      style: pw.TextStyle(
                        color: balance.balance >= 0
                            ? PdfColors.green
                            : PdfColors.red,
                      ),
                    ),
                  ],
                ),
              )),
          pw.SizedBox(height: 20),

          // Dettes
          if (debts.isNotEmpty) ...[
            pw.Text(
              'Dettes à régler',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            ...debts.map((debt) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Text(
                    '${debt.fromMemberName} doit ${debt.amount.toStringAsFixed(2)} € à ${debt.toMemberName}',
                  ),
                )),
            pw.SizedBox(height: 20),
          ],

          // Liste des dépenses
          pw.Text(
            'Détail des dépenses',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              // En-tête
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Titre', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Catégorie', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Montant', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Payé par', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              // Données
              ...expenses.map((expense) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(DateFormat('dd/MM/yyyy').format(expense.date)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(expense.title),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(expense.category),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('${expense.amount.toStringAsFixed(2)} €'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(memberNames[expense.paidBy] ?? expense.paidBy),
                      ),
                    ],
                  )),
            ],
          ),

          // Pied de page
          pw.SizedBox(height: 30),
          pw.Text(
            'Généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey,
            ),
          ),
        ],
      ),
    );

    // Sauvegarder et partager
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/depenses_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Rapport des dépenses',
    );
  }

  // Exporter en CSV
  Future<void> exportToCSV(
    List<Expense> expenses,
    Map<String, String> memberNames,
    String groupId,
  ) async {
    final List<List<dynamic>> csvData = [];

    // En-tête
    csvData.add([
      'Date',
      'Titre',
      'Catégorie',
      'Montant (€)',
      'Payé par',
      'Participants',
      'Part par personne (€)',
      'Description',
    ]);

    // Données
    for (final expense in expenses) {
      csvData.add([
        DateFormat('dd/MM/yyyy').format(expense.date),
        expense.title,
        expense.category,
        expense.amount.toStringAsFixed(2),
        memberNames[expense.paidBy] ?? expense.paidBy,
        expense.participants
            .map((id) => memberNames[id] ?? id)
            .join(', '),
        expense.sharePerPerson.toStringAsFixed(2),
        expense.description ?? '',
      ]);
    }

    // Convertir en CSV
    const converter = ListToCsvConverter();
    final csvString = converter.convert(csvData);

    // Sauvegarder et partager
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/depenses_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvString);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Rapport des dépenses (CSV)',
    );
  }
}

