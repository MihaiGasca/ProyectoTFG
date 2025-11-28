import 'package:flutter/material.dart';

class AppNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const AppNavbar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFFFF8A80),
      title: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 12, top: 4, bottom: 4),
            child: Image.asset(
              "assets/appTFG_Logo.png",
              height: 70,
            ),
          ),

          // Texto "TherapyFind"
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          )
        ],
      ),
      centerTitle: false, 
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
