import 'package:flutter/material.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final bool showHomeButton;

  const MainLayout({
    super.key,
    required this.child,
    this.title = "ArmonIA",
    this.showHomeButton = true,
  });

  void _onTap(BuildContext context, int index) {
    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }

    if (index == 1) {
      Navigator.pushNamed(context, "/exercises");
      return;
    }

    if (index == 2) {
      Navigator.pushNamed(context, "/history");
      return;
    }

    if (index == 3) {
      Navigator.pushNamed(context, "/fono");
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7FA8B8),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: showHomeButton
            ? IconButton(
                icon: const Icon(Icons.home),
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              )
            : null,
        toolbarHeight: 56,
      ),
      body: child,
      bottomNavigationBar: keyboardOpen
          ? null
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF7FA8B8),
              unselectedItemColor: Colors.black54,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              onTap: (i) => _onTap(context, i),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: "Inicio",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.self_improvement),
                  label: "Ayuda breve",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: "Historial",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.phone),
                  label: "Fono Ayuda",
                ),
              ],
            ),
    );
  }
}