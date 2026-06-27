import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'logic/auth_provider.dart';
import 'logic/brigada_provider.dart';
import 'logic/sector_provider.dart';
import 'logic/vacunador_provider.dart';

import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/primer_login_screen.dart';
import 'presentation/screens/auth/nueva_contrasena_screen.dart';

import 'presentation/screens/coordinador_brigada/dashboard_brigada_screen.dart';
import 'presentation/screens/coordinador_campana/dashboard_campana_screen.dart';
import 'presentation/screens/vacunador/panel_vacunador_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zczltjzrkoflbjmtxjus.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpjemx0anpya29mbGJqbXR4anVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNzQ1NDQsImV4cCI6MjA5Mzc1MDU0NH0.85FIEf40W1BN42tAkfaCg8GDWAlJ0mZnBhhjDUXQO8A',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SectorProvider()),
        ChangeNotifierProvider(create: (_) => BrigadaProvider()),
        ChangeNotifierProvider(create: (_) => VacunadorProvider()),
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
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(
        context,
        listen: false,
      ).verificarSesionActiva();
    });

    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    try {
      // Si la app estaba cerrada
      final Uri? initialLink = await _appLinks.getInitialLink();

      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }

      // Si la app ya estaba abierta
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          _handleDeepLink(uri);
        },
      );
    } catch (e) {
      debugPrint("Error DeepLink: $e");
    }
  }

  void _handleDeepLink(Uri uri) {
    debugPrint("Deep Link recibido:");
    debugPrint(uri.toString());

    if (uri.scheme == "com.vacunacion.app" &&
        uri.host == "reset-password") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const NuevaContrasenaScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authProvider.usuarioActual == null) {
      return const LoginScreen();
    }

    if (authProvider.usuarioActual!.requiereCambioClave) {
      return const PrimerLoginScreen();
    }

    switch (authProvider.usuarioActual!.rol) {
      case 'coordinador_campana':
        return const DashboardCampanaScreen();

      case 'coordinador_brigada':
        return const DashboardBrigadaScreen();

      case 'vacunador':
        return const PanelVacunadorScreen();

      default:
        return const Scaffold(
          body: Center(
            child: Text("Rol no reconocido"),
          ),
        );
    }
  }
}