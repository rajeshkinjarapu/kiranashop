import 'dart:convert' show utf8;
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' hide Category;
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../services/download_service.dart';
import '../../services/firestore_service.dart';

class ParsedImportProduct {
  final String name;
  final String categoryName;
  final double price;
  final String unit;
  final String description;
  final int stockQty;
  final String imageUrl;

  ParsedImportProduct({
    required this.name,
    required this.categoryName,
    required this.price,
    required this.unit,
    required this.description,
    required this.stockQty,
    required this.imageUrl,
  });
}

class BulkProductImportScreen extends StatefulWidget {
  const BulkProductImportScreen({super.key});

  @override
  State<BulkProductImportScreen> createState() => _BulkProductImportScreenState();
}

class _BulkProductImportScreenState extends State<BulkProductImportScreen> {
  final _firestore = FirestoreService();

  bool _isParsing = false;
  bool _isImporting = false;
  String? _fileName;
  List<ParsedImportProduct> _parsedProducts = [];

  static const List<String> _expectedHeaders = [
    'Product Name',
    'Category',
    'Price',
    'Unit',
    'Description',
    'Stock Qty',
    'Image URL',
  ];

  static const List<List<dynamic>> _sampleRows = [
    [
      'Product Name',
      'Category',
      'Price',
      'Unit',
      'Description',
      'Stock Qty',
      'Image URL'
    ],
    [
      'Aashirvaad Shuddh Chakki Atta',
      'Groceries',
      245,
      '5 kg',
      '100% pure whole wheat flour for soft rotis.',
      50,
      'https://m.media-amazon.com/images/I/81xU+c2F2eL.jpg'
    ],
    [
      'Fortune Sunlite Sunflower Oil',
      'Groceries',
      140,
      '1 L',
      'Refined sunflower cooking oil rich in vitamins.',
      40,
      'https://m.media-amazon.com/images/I/71uVbL1lV6L.jpg'
    ],
    [
      'Tata Salt Vacuum Evaporated',
      'Groceries',
      28,
      '1 kg',
      'Iodized salt trusted across Indian kitchens.',
      100,
      'https://m.media-amazon.com/images/I/61y-3hA-JML.jpg'
    ],
    [
      'Nestle Maggi 2-Minute Noodles',
      'Snacks',
      14,
      '70 g',
      'Masala instant noodles quick and delicious.',
      120,
      'https://m.media-amazon.com/images/I/81w8oE8fOLL.jpg'
    ],
    [
      'Surf Excel Easy Wash Detergent',
      'Household',
      135,
      '1 kg',
      'Superior stain removal powder for washing clothes.',
      30,
      'https://m.media-amazon.com/images/I/61r-lM8Z-AL.jpg'
    ],
  ];

  void _downloadSampleTemplate() {
    try {
      // Create Excel workbook
      final excel = excel_pkg.Excel.createExcel();

      // Remove default Sheet1
      excel.delete('Sheet1');

      // Create Products sheet
      final sheet = excel['Products'];

      // ── HEADER ROW ──────────────────────────────────────────
      final headers = [
        'Product Name',
        'Category',
        'Price',
        'Unit',
        'Description',
        'Stock Qty',
        'Image URL',
      ];

      // Style headers bold
      final headerStyle = excel_pkg.CellStyle(
        bold: true,
        backgroundColorHex: excel_pkg.ExcelColor.fromHexString('#2563EB'),
        fontColorHex: excel_pkg.ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: excel_pkg.HorizontalAlign.Center,
      );

      for (int col = 0; col < headers.length; col++) {
        final cell = sheet
            .cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.value = excel_pkg.TextCellValue(headers[col]);
        cell.cellStyle = headerStyle;
      }

      // ── SAMPLE DATA ROWS ─────────────────────────────────────
      final rows = [
        ['Aashirvaad Shuddh Chakki Atta', 'Groceries', 245, '5 kg', '100% pure whole wheat flour for soft rotis.', 50, 'https://m.media-amazon.com/images/I/81xU+c2F2eL.jpg'],
        ['Fortune Sunlite Sunflower Oil', 'Groceries', 140, '1 L', 'Refined sunflower cooking oil rich in vitamins.', 40, 'https://m.media-amazon.com/images/I/71uVbL1lV6L.jpg'],
        ['Tata Salt Vacuum Evaporated', 'Groceries', 28, '1 kg', 'Iodized salt trusted across Indian kitchens.', 100, ''],
        ['Nestle Maggi 2-Minute Noodles', 'Snacks', 14, '70 g', 'Masala instant noodles quick and delicious.', 120, ''],
        ['Surf Excel Easy Wash Detergent', 'Household', 135, '1 kg', 'Superior stain removal powder for washing clothes.', 30, ''],
        ['Amul Gold Full Cream Milk', 'Dairy', 32, '500 ml', 'Full cream fresh milk packed with nutrients.', 80, ''],
        ['Colgate MaxFresh Toothpaste', 'Personal Care', 99, '150 g', 'Cool mint flavour for strong teeth and fresh breath.', 60, ''],
        ['Parle-G Original Glucose Biscuits', 'Snacks', 10, '80 g', 'Classic Indian glucose biscuits loved by all ages.', 200, ''],
      ];

      for (int r = 0; r < rows.length; r++) {
        final rowData = rows[r];
        for (int c = 0; c < rowData.length; c++) {
          final cell = sheet.cell(
              excel_pkg.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1));
          final val = rowData[c];
          if (val is int || val is double) {
            cell.value = excel_pkg.DoubleCellValue((val as num).toDouble());
          } else {
            cell.value = excel_pkg.TextCellValue(val.toString());
          }
        }
      }

      // Set column widths
      sheet.setColumnWidth(0, 35); // Product Name
      sheet.setColumnWidth(1, 20); // Category
      sheet.setColumnWidth(2, 10); // Price
      sheet.setColumnWidth(3, 10); // Unit
      sheet.setColumnWidth(4, 45); // Description
      sheet.setColumnWidth(5, 12); // Stock Qty
      sheet.setColumnWidth(6, 50); // Image URL

      final bytes = excel.save();
      if (bytes == null) throw Exception('Failed to generate Excel file.');

      if (kIsWeb) {
        downloadBytes(
          bytes,
          'sample_kirana_products.xlsx',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Sample Excel file downloaded!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📥 Excel generated! Open it in your file manager.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel generate చేయడం failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndParseFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      final extension = (file.extension ?? '').toLowerCase();

      if (bytes == null) {
        throw Exception('Unable to read file content.');
      }

      setState(() {
        _isParsing = true;
        _fileName = file.name;
        _parsedProducts = [];
      });

      List<ParsedImportProduct> products = [];

      if (extension == 'csv') {
        final csvString = utf8.decode(bytes, allowMalformed: true);
        final rows = const CsvToListConverter().convert(csvString);
        products = _parseRows(rows);
      } else {
        // Excel format (.xlsx / .xls)
        final excel = excel_pkg.Excel.decodeBytes(bytes);
        final table = excel.tables[excel.tables.keys.first];
        if (table != null) {
          final List<List<dynamic>> rows = [];
          for (final row in table.rows) {
            rows.add(row.map((cell) => cell?.value).toList());
          }
          products = _parseRows(rows);
        }
      }

      setState(() {
        _parsedProducts = products;
      });

      if (products.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No valid product rows found in the file.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Found ${products.length} products ready for import!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reading Excel/CSV file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isParsing = false);
    }
  }

  List<ParsedImportProduct> _parseRows(List<List<dynamic>> rows) {
    if (rows.isEmpty) return [];

    final List<ParsedImportProduct> list = [];

    // Check if first row is header
    int startIdx = 0;
    final firstRowStr = rows.first.map((e) => e.toString().toLowerCase()).toList();
    if (firstRowStr.any((s) => s.contains('name') || s.contains('product'))) {
      startIdx = 1; // Skip header row
    }

    for (int i = startIdx; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      final name = _getCol(row, 0);
      if (name.isEmpty) continue;

      final category = _getCol(row, 1, fallback: 'General');
      final priceStr = _getCol(row, 2, fallback: '0');
      final unit = _getCol(row, 3, fallback: '1 Pkt');
      final description = _getCol(row, 4);
      final stockStr = _getCol(row, 5, fallback: '50');
      final imageUrl = _getCol(row, 6);

      final price = double.tryParse(priceStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      final stockQty = int.tryParse(stockStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 50;

      list.add(ParsedImportProduct(
        name: name,
        categoryName: category.isNotEmpty ? category : 'General',
        price: price,
        unit: unit,
        description: description,
        stockQty: stockQty,
        imageUrl: imageUrl,
      ));
    }

    return list;
  }

  String _getCol(List<dynamic> row, int index, {String fallback = ''}) {
    if (index >= row.length) return fallback;
    final val = row[index];
    if (val == null) return fallback;
    final str = val.toString().trim();
    return str.isEmpty ? fallback : str;
  }

  Future<void> _startBulkImport() async {
    if (_parsedProducts.isEmpty) return;

    setState(() => _isImporting = true);

    try {
      final existingCategories = context.read<ProductProvider>().categories;
      final categoryMap = <String, Category>{};
      for (final c in existingCategories) {
        categoryMap[c.name.toLowerCase().trim()] = c;
      }

      int importedCount = 0;

      for (final item in _parsedProducts) {
        final catKey = item.categoryName.toLowerCase().trim();
        Category? targetCat = categoryMap[catKey];

        // Auto-create Category if it doesn't exist
        if (targetCat == null) {
          final newCatId = DateTime.now().millisecondsSinceEpoch.toString();
          final newCat = Category(
            id: newCatId,
            name: item.categoryName,
            imageUrl: '',
          );
          await _firestore.saveCategory(newCat);
          categoryMap[catKey] = newCat;
          targetCat = newCat;
        }

        final product = Product(
          id: '',
          name: item.name,
          description: item.description,
          categoryId: targetCat.id,
          categoryName: targetCat.name,
          price: item.price,
          unit: item.unit,
          imageUrl: item.imageUrl,
          stockQty: item.stockQty,
          inStock: true,
          isFeatured: false,
          isActive: true,
        );

        await _firestore.saveProduct(product);
        importedCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Successfully imported $importedCount products to store!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulk import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Bulk Product Import',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── HEADER ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.table_chart_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Excel / CSV Bulk Import',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 3),
                        Text(
                          'Upload hundreds of products in one go!\nSupports .xlsx, .xls and .csv formats.',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── STEP 1: SAMPLE TEMPLATE ──────────────────────────────────
            _stepCard(
              step: '1',
              color: const Color(0xFF3B82F6),
              title: 'Download Sample Template',
              subtitle:
                  'Get the CSV with correct columns & sample Kirana products.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columns chip row
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      'A. Product Name',
                      'B. Category',
                      'C. Price',
                      'D. Unit',
                      'E. Description',
                      'F. Stock Qty',
                      'G. Image URL',
                    ]
                        .map(
                          (col) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Text(col,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF1E40AF),
                                    fontWeight: FontWeight.w600)),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _downloadSampleTemplate,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('⬇ Download Sample Excel (.XLSX)',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '💡 Image URL: paste a direct image link (Amazon/Google Images)',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── STEP 2: UPLOAD FILE ──────────────────────────────────────
            _stepCard(
              step: '2',
              color: const Color(0xFF10B981),
              title: 'Upload Your Filled Spreadsheet',
              subtitle: 'Select your Excel (.xlsx) or CSV file.',
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isParsing ? null : _pickAndParseFile,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _fileName != null
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _fileName != null
                              ? const Color(0xFF10B981)
                              : const Color(0xFFCBD5E1),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          if (_isParsing)
                            const CircularProgressIndicator(
                                color: Color(0xFF10B981))
                          else
                            Icon(
                              _fileName != null
                                  ? Icons.check_circle_rounded
                                  : Icons.cloud_upload_outlined,
                              size: 44,
                              color: _fileName != null
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF94A3B8),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            _isParsing
                                ? 'Reading file...'
                                : _fileName != null
                                    ? _fileName!
                                    : 'Tap to choose file',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _fileName != null
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF64748B),
                              fontSize: 14,
                            ),
                          ),
                          if (_fileName == null && !_isParsing) ...[
                            const SizedBox(height: 2),
                            const Text('Supports .xlsx  •  .xls  •  .csv',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8))),
                          ],
                          if (_parsedProducts.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(
                                '${_parsedProducts.length} products found',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF10B981),
                        side: const BorderSide(
                            color: Color(0xFF10B981), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isParsing ? null : _pickAndParseFile,
                      icon: const Icon(Icons.folder_open_rounded),
                      label: Text(
                        _isParsing
                            ? 'Reading...'
                            : _fileName != null
                                ? 'Choose Different File'
                                : 'Choose Excel / CSV File',
                        style:
                            const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── STEP 3: PREVIEW & IMPORT ─────────────────────────────────
            if (_parsedProducts.isNotEmpty)
              _stepCard(
                step: '3',
                color: const Color(0xFF8B5CF6),
                title: 'Preview & Import (${_parsedProducts.length} products)',
                subtitle:
                    'Review products below, then tap Import to add to store.',
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: _isImporting ? null : _startBulkImport,
                        icon: _isImporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.publish_rounded),
                        label: Text(
                          _isImporting
                              ? 'Importing...'
                              : '🚀 Import All ${_parsedProducts.length} Products',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _parsedProducts.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) =>
                          _productTile(_parsedProducts[i]),
                    ),
                  ],
                ),
              )
            else if (_fileName != null && !_isParsing)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange.shade700, size: 34),
                    const SizedBox(height: 6),
                    Text('No valid products found.',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800)),
                    const SizedBox(height: 4),
                    Text(
                      'Check that columns match the sample template.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.orange.shade700),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── STEP CARD ──────────────────────────────────────────────────────────────
  Widget _stepCard({
    required String step,
    required Color color,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                  bottom:
                      BorderSide(color: color.withOpacity(0.15), width: 1)),
            ),
            child: Row(children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
                child: Text(step,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1E293B))),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ]),
          ),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }

  // ── PRODUCT TILE ───────────────────────────────────────────────────────────
  Widget _productTile(ParsedImportProduct p) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(children: [
        Container(
          width: 56,
          height: 56,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          clipBehavior: Clip.antiAlias,
          child: p.imageUrl.isNotEmpty
              ? Image.network(p.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_not_supported_outlined,
                      color: Color(0xFF94A3B8),
                      size: 22))
              : const Icon(Icons.inventory_2_outlined,
                  color: Color(0xFF94A3B8), size: 22),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1E293B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.category_outlined,
                      size: 11, color: Color(0xFF6366F1)),
                  const SizedBox(width: 3),
                  Text(p.categoryName,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  const Icon(Icons.straighten_outlined,
                      size: 11, color: Color(0xFF0EA5E9)),
                  const SizedBox(width: 3),
                  Text(p.unit,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF0EA5E9),
                          fontWeight: FontWeight.w600)),
                ]),
                if (p.description.isNotEmpty)
                  Text(p.description,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${p.price % 1 == 0 ? p.price.toInt() : p.price.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Color(0xFF10B981)),
              ),
              const SizedBox(height: 3),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(5)),
                child: Text('Qty: ${p.stockQty}',
                    style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}