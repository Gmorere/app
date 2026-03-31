import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/main_layout.dart';

class TrustedContactScreen extends StatefulWidget {
  const TrustedContactScreen({super.key});

  @override
  State<TrustedContactScreen> createState() => _TrustedContactScreenState();
}

class _TrustedContactScreenState extends State<TrustedContactScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContact();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) {
      return 'Ingresa un tel\u00e9fono v\u00e1lido.';
    }
    return null;
  }

  Future<void> _loadContact() async {
    final contact = await AuthService.getTrustedContact();
    if (!mounted) return;

    if (contact != null) {
      _nameController.text = contact.name;
      _phoneController.text = contact.phone;
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      setState(() {
        _errorMessage = 'Ingresa nombre y tel\u00e9fono.';
      });
      return;
    }

    final phoneError = _validatePhone(phone);
    if (phoneError != null) {
      setState(() {
        _errorMessage = phoneError;
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    await AuthService.saveTrustedContact(
      name: name,
      phone: phone,
    );

    if (!mounted) return;
    setState(() {
      _saving = false;
    });

    Navigator.pop(context, true);
  }

  Future<void> _clear() async {
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    await AuthService.clearTrustedContact();

    if (!mounted) return;
    _nameController.clear();
    _phoneController.clear();
    setState(() {
      _saving = false;
    });

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Contacto de confianza',
      child: Container(
        color: const Color(0xFFF8FAFB),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Agrega a una persona a la que puedas llamar si necesitas apoyo r\u00e1pido. Es una opci\u00f3n complementaria a Fono Ayuda.',
                      style: TextStyle(
                        fontSize: 14.5,
                        color: Colors.black87,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FormCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Nombre',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            hintText: 'Ej. Ana o Mam\u00e1',
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Tel\u00e9fono',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: 'Ej. +56 9 1234 5678',
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFF9A4D4D),
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Guardar contacto'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_nameController.text.isNotEmpty ||
                      _phoneController.text.isNotEmpty)
                    SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _saving ? null : _clear,
                        child: const Text('Eliminar contacto'),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;

  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
