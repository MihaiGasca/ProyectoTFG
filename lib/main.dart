import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:provider/provider.dart';
import 'package:tfg/providers/unread_provider.dart';
import 'package:tfg/screens/login/pantalla_login.dart';
import 'package:tfg/screens/home/principal.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:'https://mqloukaqxmoyfhmpwtdh.supabase.co',
    anonKey:'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1xbG91a2FxeG1veWZobXB3dGRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEyNTU4MzYsImV4cCI6MjA3NjgzMTgzNn0.XoqeWREM8_0KK_QleTJTFI2qiNkBn0Zm3RWI6BJk9sc',

  );

  runApp(const MiApp());
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UnreadProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TherapyFind',
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFFFFEDEB),
          primaryColor: const Color(0xFFFF8A80),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFF8A80),
            foregroundColor: Colors.white,
            elevation: 2,
            centerTitle: true,
          ),
        ),
        home: const Root(),
      ),
    );
  }
}

class Root extends StatefulWidget {
  const Root({super.key});
  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  bool _checking = true;
  User? _user;

  @override
  void initState() {
    super.initState();
    _checkAuth();

    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (!mounted) return;

    setState(() {
      _user = user;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _user == null ? const PantallaLogin() : const PaginaUsuarios();
  }
}
