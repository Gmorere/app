import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/backend_config.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const Duration _submitTimeout = Duration(seconds: 45);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  String? _errorMessage;
  Future<void>? _warmupFuture;

  @override
  void initState() {
    super.initState();
    _warmupFuture = _wakeBackend();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _wakeBackend() async {
    try {
      await http
          .get(Uri.parse('${BackendConfig.baseUrl}/health'))
          .timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  String _buildErrorMessage(int statusCode, dynamic decoded) {
    if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
      final detail = decoded['detail'].toString().trim();
      if (detail.isNotEmpty && detail.toLowerCase() != 'not found') {
        return detail;
      }
    }

    if (statusCode == 404) {
      return 'El backend activo no encontro esta ruta. Revisa que el deploy publicado corresponda a esta version de ArmonIA.';
    }

    if (statusCode >= 500) {
      return 'El backend no pudo responder en este momento. Intentalo nuevamente en unos minutos.';
    }

    return _isLoginMode
        ? 'No pude iniciar sesion ahora.'
        : 'No pude crear la cuenta ahora.';
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final displayName = _displayNameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Completa correo y contrasena.';
      });
      return;
    }

    if (!_isLoginMode && displayName.isEmpty) {
      setState(() {
        _errorMessage = 'Completa tu nombre para crear la cuenta.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await (_warmupFuture ?? _wakeBackend());

      final uri = Uri.parse(
        _isLoginMode
            ? '${BackendConfig.baseUrl}/auth/login'
            : '${BackendConfig.baseUrl}/auth/register',
      );

      final body = _isLoginMode
          ? {
              'email': email,
              'password': password,
            }
          : {
              'email': email,
              'password': password,
              'display_name': displayName,
            };

      Future<http.Response> sendRequest() {
        return http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode(body),
            )
            .timeout(_submitTimeout);
      }

      http.Response response;
      try {
        response = await sendRequest();
      } on TimeoutException {
        await _wakeBackend();
        response = await sendRequest();
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        setState(() {
          _errorMessage = _buildErrorMessage(response.statusCode, decoded);
          _isLoading = false;
        });
        return;
      }

      if (decoded is! Map<String, dynamic>) {
        setState(() {
          _errorMessage = 'La respuesta del servidor no llego en un formato valido.';
          _isLoading = false;
        });
        return;
      }

      final token = (decoded['access_token'] ?? '').toString();

      if (token.isEmpty) {
        setState(() {
          _errorMessage = 'No llego el token de acceso.';
          _isLoading = false;
        });
        return;
      }

      await AuthService.saveToken(token);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(authToken: token),
        ),
      );
    } on TimeoutException {
      setState(() {
        _errorMessage =
            'El backend tardó demasiado en responder. Puede estar despertando en Render. Intenta nuevamente en unos segundos.';
        _isLoading = false;
      });
    } on http.ClientException {
      setState(() {
        _errorMessage = 'No pude conectarme con el backend en este momento.';
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'No pude conectarme con el backend en este momento.';
        _isLoading = false;
      });
    }
  }

  void _toggleMode() {
    if (_isLoading) return;

    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF7FA8B8);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.self_improvement,
                    size: 52,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isLoginMode ? 'Entrar a ArmonIA' : 'Crear cuenta',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isLoginMode
                        ? 'Ingresa para continuar con tu espacio emocional.'
                        : 'Crea una cuenta para comenzar tu beta privada.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!_isLoginMode) ...[
                    TextField(
                      controller: _displayNameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Correo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Contrasena',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4F4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8A5C5C),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isLoginMode ? 'Entrar' : 'Crear cuenta',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _toggleMode,
                    child: Text(
                      _isLoginMode
                          ? 'No tengo cuenta todavia'
                          : 'Ya tengo cuenta',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
