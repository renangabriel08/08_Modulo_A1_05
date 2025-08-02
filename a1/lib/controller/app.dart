import 'package:flutter/material.dart';

class App {
  static bool modalBateria = false;

  static showModalBateria(BuildContext context) {
    modalBateria = true;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Atenção. Bateria baixa.'),
        content: Image.asset('assets/bateria.png'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
