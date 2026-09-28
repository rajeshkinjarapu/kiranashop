import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/offer.dart';
import '../../services/firestore_service.dart';
import '../../widgets/network_image_box.dart';

class OfferFormScreen extends StatefulWidget {
  final Offer? offer;

  const OfferFormScreen({super.key, this.offer});

  @override
  State<OfferFormScreen> createState() => _OfferFormScreenState();
}

class _OfferFormScreenState extends State<OfferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirestoreService();
  final _picker = ImagePicker();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _subtitleCtrl;
  late final TextEditingController _orderCtrl;

  bool _isActive = true;
  bool _saving = false;
  Uint8List? _pickedImageBytes;
  String _existingImageUrl = '';

  @override
  void initState() {
    super.initState();
    final o = widget.offer;
    _titleCtrl = TextEditingController(text: o?.title ?? '');
    _subtitleCtrl = TextEditingController(text: o?.subtitle ?? '');
    _orderCtrl = TextEditingController(text: '${o?.sortOrder ?? 0}');
    _isActive = o?.isActive ?? true;
    _existingImageUrl = o?.imageUrl ?? '';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _pickedImageBytes = bytes);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      var imageUrl = _existingImageUrl;
      if (_pickedImageBytes != null) {
        imageUrl = 'data:image/jpeg;base64,${base64Encode(_pickedImageBytes!)}';
      }
      final existing = widget.offer;
      final offer = Offer(
        id: existing?.id ?? '',
        title: _titleCtrl.text.trim(),
        subtitle: _subtitleCtrl.text.trim(),
        imageUrl: imageUrl,
        isActive: _isActive,
        sortOrder: int.tryParse(_orderCtrl.text.trim()) ?? 0,
      );
      await _firestore.saveOffer(
        offer,
        id: (existing?.id ?? '').isEmpty ? null : existing?.id,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save offer: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.offer != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Offer' : 'Add Offer',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0265DC),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: _pickedImageBytes != null
                      ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
                      : _existingImageUrl.isNotEmpty
                          ? NetworkImageBox(
                              url: _existingImageUrl,
                              height: 160,
                              width: double.infinity,
                            )
                          : Container(
                              color: const Color(0xFFE2E8F0),
                              alignment: Alignment.center,
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined,
                                      size: 40, color: Color(0xFF64748B)),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap to add banner image',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. 20% off on rice',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subtitleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Subtitle (optional)',
                hintText: 'e.g. This week only',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _orderCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Sort order',
                hintText: '0 = first banner',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show on home'),
              subtitle: Text(
                _isActive
                    ? 'Customers will see this banner'
                    : 'Hidden from customers',
              ),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0265DC),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isEdit ? 'Save changes' : 'Add offer'),
            ),
          ],
        ),
      ),
    );
  }
}
