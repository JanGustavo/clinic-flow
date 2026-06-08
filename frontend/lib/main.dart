import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:frontend/pages/forgot.dart';
import 'package:frontend/pages/register.dart';
import 'package:frontend/pages/home.dart';
import 'package:frontend/pages/login.dart';
import 'package:frontend/pages/recover.dart';
import 'package:frontend/pages/consultas.dart';
import 'package:frontend/pages/procedimentos.dart';
import 'package:frontend/pages/procedimentos_recomendados.dart';
import 'package:frontend/pages/profile.dart';
import 'package:frontend/pages/admin.dart';



void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClinicFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: const Color(0xFFE6F0FF),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('pt'),
      ],
      locale: const Locale('pt', 'BR'),
      // Página inicial: Login
      home: const LoginScreen(),
      routes: {
        // Autenticação
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot': (_) => const ForgotScreen(),
        '/recover': (_) => const RecoverScreen(),

        // Navegação principal (após login)
        '/home': (_) => const HomePage(),
        '/perfil': (_) => const ProfileScreen(),
        '/consultas': (_) => const ConsultasScreen(),
        '/procedimentos': (_) => const ProcedimentosScreen(),
        '/procedimentos_recomendados': (_) =>
            const ProcedimentosRecomendadosScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/admin': (_) => const AdminScreen(),
      },
    );
  }
}
