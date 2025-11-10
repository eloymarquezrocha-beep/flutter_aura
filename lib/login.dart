import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glass/glass.dart';
import 'chat_screen.dart';
import 'register_screen.dart';
import 'wave.dart';

// --- (AÑADIDO) Imports para la API y el Token ---
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// --- (AÑADIDO) La IP de tu servidor ---
const String API_BASE = "https://dragonpardo.com";
class LoginScreen extends StatefulWidget {
 const LoginScreen({super.key});

 @override
 State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
 final TextEditingController emailController = TextEditingController();
 final TextEditingController passwordController = TextEditingController();
 bool obscurePassword = true;

  // --- (AÑADIDO) Variables de estado para la API ---
  final _storage = const FlutterSecureStorage();
  String _errorMessage = '';
  bool _isLoading = false;

  // --- (AÑADIDO) Función para llamar a tu API de Flask ---
  Future<void> _handleLogin() async {
    // 1. Mostrar estado "Pensando..."
    setState(() { _isLoading = true; _errorMessage = ''; });

    try {
      // 2. Preparar el payload
      final payload = jsonEncode({
        "email": emailController.text.trim(),
        "password": passwordController.text.trim()
      });

      // 3. Hacer la petición POST a tu servidor
      final res = await http.post(
        Uri.parse("$API_BASE/login"),
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );
      
      final data = jsonDecode(res.body);
      
      // 4. Procesar la respuesta
      if (res.statusCode == 200 && data['access_token'] != null) {
        // ¡ÉXITO! Guarda el token de forma segura
        await _storage.write(key: "aura_token", value: data['access_token']);
        
        // ¡Navegamos a la pantalla de Chat!
        // Usamos 'pushReplacement' para que el usuario no pueda "volver"
        // a la pantalla de login una vez que ya entró.
        if (mounted) { // Comprueba si el widget sigue en pantalla
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
                initialMessages: const [],
              ),
            ),
          );
        }

      } else {
        // Muestra el error del servidor (ej. "Contraseña incorrecta")
        setState(() { _errorMessage = data['error'] ?? 'Error desconocido'; });
      }
    } catch (e) {
      // Error de Red (ej. "Failed to fetch")
      setState(() { _errorMessage = "Error: ${e.toString()}"; });
    }
    
    // 5. Dejar de "pensar"
    setState(() { _isLoading = false; });
  }

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
 _buildEmailField(screenWidth),
 const SizedBox(height: 16),
 _buildPasswordField(screenWidth),
const SizedBox(height: 24),
 _buildLoginButton(screenWidth),
const SizedBox(height: 20),

                  // --- (AÑADIDO) Muestra de errores ---
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.redAccent, 
                          fontFamily: 'MonosRegular',
                          fontSize: 14,
                        ),
                      ),
                    ),

 _buildLinks(),
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

 Widget _buildEmailField(double width) {
 return Container(
 width: width * 0.8,
 height: width * 0.12,
 alignment: Alignment.center,
 decoration: BoxDecoration(
 borderRadius: BorderRadius.circular(30),
 border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.3),
 ),
 child: TextField(
 controller: emailController,
 keyboardType: TextInputType.emailAddress,
 style: const TextStyle(
 color: Colors.white,
 fontFamily: 'MonosRegular',
),
 decoration: InputDecoration(
 border: InputBorder.none,
 contentPadding: const EdgeInsets.symmetric(horizontal: 18),
 hintText: 'Correo',
 hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
 ),
 ),
 ).asGlass(
 tintColor: Colors.white.withOpacity(0.05),
blurX: 15,
 blurY: 15,
 clipBorderRadius: BorderRadius.circular(30),
 );
 }

 Widget _buildPasswordField(double width) {
return Container(
 width: width * 0.8,
 height: width * 0.12,
 alignment: Alignment.center,
 decoration: BoxDecoration(
 borderRadius: BorderRadius.circular(30),
 border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.3),
 ),
 child: Row(
children: [
Expanded(
 child: TextField(
 controller: passwordController,
 obscureText: obscurePassword,
 style: const TextStyle(
 color: Colors.white,
 fontFamily: 'MonosRegular',
 ),
 decoration: InputDecoration(
 border: InputBorder.none,
 contentPadding: const EdgeInsets.symmetric(horizontal: 18),
 hintText: 'Contraseña',
 hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
 ),
 ),
 ),
 IconButton(
 icon: Icon(
 obscurePassword
 ? Icons.visibility_outlined
 : Icons.visibility_off_outlined,
 color: Colors.white.withOpacity(0.6),
 size: 20,
),
onPressed: () {
setState(() => obscurePassword = !obscurePassword);

},
),
],
),
).asGlass(
tintColor: Colors.white.withOpacity(0.05),
 blurX: 15,
blurY: 15,
clipBorderRadius: BorderRadius.circular(30),
 );
}

 Widget _buildLoginButton(double width) {
return SizedBox(
 width: width * 0.6,
height: width * 0.12,
child: ElevatedButton(
        // --- (MODIFICADO) Llama a la API y se deshabilita si está cargando ---
 onPressed: _isLoading ? null : _handleLogin,
 style: ElevatedButton.styleFrom(
backgroundColor: const Color.fromARGB(91, 74, 74, 74),
elevation: 0,
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(30),
 side: BorderSide(
 color: const Color.fromARGB(100, 255, 255, 255),
 width: 1.3,
 ),
 ),
),
        // --- (MODIFICADO) Muestra un círculo de carga ---
 child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
    'Iniciar sesión',
    style: TextStyle(
    color: Colors.white,
     fontFamily: 'MonosRegular',
     fontSize: 15,
    letterSpacing: 1.1,
    ),
    ),
 ),
 ).asGlass(
tintColor: const Color.fromARGB(92, 255, 255, 255),
 blurX: 15,
 blurY: 15,
 clipBorderRadius: BorderRadius.circular(30),
);
 }

 Widget _buildLinks() {
  return Column(
   children: [
    GestureDetector(
     onTap: () {
      Navigator.push(
       context,
       MaterialPageRoute(builder: (context) => const RegisterScreen()),
      );
     },
     child: const Text(
      'Crear cuenta',
      style: TextStyle(
       color: Colors.white70,
       fontFamily: 'MonosRegular',
       decoration: TextDecoration.underline,
       decorationColor: Colors.white38,
      ),
     ),
    ),
    const SizedBox(height: 10),
    GestureDetector(
     onTap: () {
          // Aquí iría la navegación a la pantalla de "Olvidé contraseña"
        },
     child: const Text(
      'Olvidé mi contraseña',
      style: TextStyle(
       color: Colors.white70,
       fontFamily: 'MonosRegular',
       decoration: TextDecoration.underline,
       decorationColor: Colors.white38,
      ),
          ),
        ),
      ],
    );
  }
}