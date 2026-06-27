import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'logic/auth_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/primer_login_screen.dart';
import 'presentation/screens/coordinador_campana/dashboard_campana_screen.dart';
import 'logic/sector_provider.dart';
import 'logic/brigada_provider.dart';
import 'presentation/screens/coordinador_brigada/dashboard_brigada_screen.dart';
import 'logic/vacunador_provider.dart';
import 'presentation/screens/vacunador/panel_vacunador_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Reemplaza con las credenciales de tu proyecto de Supabase
  await Supabase.initialize(
    url: 'https://zczltjzrkoflbjmtxjus.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpjemx0anpya29mbGJqbXR4anVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNzQ1NDQsImV4cCI6MjA5Mzc1MDU0NH0.85FIEf40W1BN42tAkfaCg8GDWAlJ0mZnBhhjDUXQO8A',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SectorProvider()),
        ChangeNotifierProvider(create: (_) => BrigadaProvider()),
        ChangeNotifierProvider(create: (_) => VacunadorProvider()),
        // Aquí añadirás los demás providers conforme los programemos
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campaña Vacunación',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const LoginCheck(),
    );
  }
}

class LoginCheck extends StatefulWidget {
  const LoginCheck({super.key});

  @override
  State<LoginCheck> createState() => _LoginCheckState();
}

class _LoginCheckState extends State<LoginCheck> {
  @override
  void initState() {
    super.initState();
    // Ejecuta la verificación de persistencia tras renderizar el primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).verificarSesionActiva();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authProvider.usuarioActual == null) {
      return const LoginScreen(); // Cambiado
    }

    if (authProvider.usuarioActual!.requiereCambioClave) {
      return const PrimerLoginScreen(); // Cambiado
    }

    // Si ya está logeado y cambió su clave, derivamos por Rol a su interfaz
    switch (authProvider.usuarioActual!.rol) {
      case 'coordinador_campana':
        return const DashboardCampanaScreen(); // <-- Cambiado aquí
      case 'coordinador_brigada':
        return const DashboardBrigadaScreen();
      case 'vacunador':
        return const PanelVacunadorScreen();
      default:
        return const Scaffold(body: Center(child: Text("Rol no reconocido")));
    }
  }
}

