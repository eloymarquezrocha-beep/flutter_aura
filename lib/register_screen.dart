import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glass/glass.dart';
import 'wave.dart';

// --- (AÑADIDO) Imports para la API ---
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- (AÑADIDO) La IP de tu servidor ---
const String API_BASE = "https://dragonpardo.com";
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<StatefulWidget> createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirm = true;

  // --- (AÑADIDO) Variables de estado para la API ---
  String _message = '';
  bool _isLoading = false;

  // --- (AÑADIDO) Función para llamar a tu API de Flask ---
  Future<void> _handleRegister() async {
    // 1. Validar que las contraseñas coincidan
    if (passwordController.text != confirmController.text) {
      setState(() { _message = "Las contraseñas no coinciden"; });
      return;
    }

    // 2. Mostrar estado "Pensando..."
    setState(() { _isLoading = true; _message = ''; });

    try {
      // 3. Preparar el payload
      final payload = jsonEncode({
        "nombre": nameController.text.trim(),
        "email": emailController.text.trim(),
        "password": passwordController.text.trim()
      });

      // 4. Hacer la petición POST a tu servidor
      final res = await http.post(
        Uri.parse("$API_BASE/register"),
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );
      
      final data = jsonDecode(res.body);

      // 5. Procesar la respuesta
      if (res.statusCode == 201) { // 201 = Created (Éxito)
        setState(() { 
          _message = "¡Usuario registrado! Serás redirigido al login..."; 
        });
        
        // Espera 2 segundos y regresa a la pantalla de Login
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context); // 'pop' regresa a la pantalla anterior
          }
        });

      } else {
        // Muestra el error del servidor (ej. "El correo ya está registrado")
        setState(() { _message = data['error'] ?? 'Error desconocido'; });
      }
    } catch (e) {
      // Error de Red
      setState(() { _message = "Error de Red. Revisa la conexión."; });
    }
    
    // 6. Dejar de "pensar"
    setState(() { _isLoading = false; });
  }


  final double keyboardDistance = 20;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Fondo
            Container(color: const Color(0xFF131313)),

            // Círculo animado
            Positioned(
              top: screenWidth * 0.25,
              left: 0,
              right: 0,
              child: Center(
                child: WaveCircle(
                  size: screenWidth * 0.9,
                  speed: 1.2,
                  amplitude: 10,
                  rings: 4,
                  color: Colors.white,
                ),
              ),
            ),

            // Formulario pegado abajo y ajustable al teclado
            Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                reverse: true,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: 1,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildInputField(
                      screenWidth,
                      controller: nameController,
                      hint: "Nombre",
                    ),
                    const SizedBox(height: 14),
                    _buildInputField(
                      screenWidth,
                      controller: emailController,
                      hint: "Correo",
                      keyboard: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _buildInputField(
                      screenWidth,
                      controller: passwordController,
                      hint: "Contraseña",
                      obscure: true,
                      toggleObscure: () {
                        setState(() => obscurePassword = !obscurePassword);
                      },
                      obscureValue: obscurePassword,
                    ),
                    const SizedBox(height: 14),
                    _buildInputField(
                      screenWidth,
                      controller: confirmController,
                      hint: "Confirmar contraseña",
                      obscure: true,
                      toggleObscure: () {
                        setState(() => obscureConfirm = !obscureConfirm);
                      },
                      obscureValue: obscureConfirm,
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: screenWidth * 0.6,
                      height: screenWidth * 0.12,
                      child: ElevatedButton(
                        // --- (MODIFICADO) ---
                        onPressed: _isLoading ? null : _handleRegister,
                        // --------------------
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A4A4A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: const BorderSide(
                                color: Color.fromARGB(100, 255, 255, 255),
                                width: 1.3),
                          ),
                          elevation: 0,
                        ),
                        // --- (MODIFICADO) ---
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3,)
                            : const Text(
                                'Crear Cuenta',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'monospace',
                                    fontSize: 15,
                                    letterSpacing: 1.1),
                              ),
                        // --------------------
                      ).asGlass(
                        tintColor: const Color.fromARGB(200, 255, 255, 255),
                        blurX: 15,
                        blurY: 15,
                        clipBorderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // --- (AÑADIDO) Widget para mostrar mensajes ---
                    if (_message.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Text(
                          _message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _message.startsWith("¡Usuario registrado!") ? Colors.greenAccent : Colors.redAccent,
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    // ------------------------------------------

                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Ya tengo cuenta',
                        style: TextStyle(
                          color: Colors.white70,
                          fontFamily: 'monospace',
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    double screenWidth, {
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
    VoidCallback? toggleObscure,
    bool obscureValue = true,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.15),
      child: Container(
        height: 55,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.3),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                obscureText: obscure ? obscureValue : false,
                keyboardType: keyboard,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                  hintText: hint,
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ),
            ),
            if (obscure && toggleObscure != null)
              IconButton(
                icon: Icon(
                  obscureValue
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white.withOpacity(0.6),
                  size: 20,
                ),
                onPressed: toggleObscure,
              ),
          ],
        ),
      ).asGlass(
        tintColor: Colors.white.withOpacity(0.05),
        blurX: 15,
        blurY: 15,
        clipBorderRadius: BorderRadius.circular(30),
      ),
    );
  }
}