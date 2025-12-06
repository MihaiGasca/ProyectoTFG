import 'package:flutter/material.dart';

class AppNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const AppNavbar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 4,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF8A80),
              Color(0xFFFFB3AC),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Image.asset(
              "assets/appTFG_Logo.png",
              height: 42,
            ),
          ),

          // Texto TherapyFind
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      centerTitle: false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(65);
}
