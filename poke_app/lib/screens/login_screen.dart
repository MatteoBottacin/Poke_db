import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../db_helper.dart';
import 'home_screen.dart';

const String BASE_URL = "http://192.168.1.8/poke-api";

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username  = TextEditingController();
  final _password  = TextEditingController();
  final _email     = TextEditingController();
  bool _isRegister = false;
  String _msg      = '';

  @override
  void initState() {
    super.initState();
    _checkSessione();
  }

  // se c'è già una sessione salvata vai direttamente alla home
  void _checkSessione() async {
    final sessioni = await DBHelper.getAll("sessione");
    if (sessioni.isNotEmpty) {
      final s = sessioni.last;
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => HomeScreen(userId: s["user_id"], username: s["username"]),
      ));
    }
  }

  void _submit() async {
    if (_isRegister) {
      final res = await http.post(
        Uri.parse("$BASE_URL/utenti.php?action=register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": _username.text, "password": _password.text, "email": _email.text}),
      );
      if (res.statusCode == 201) {
        setState(() { _isRegister = false; _msg = "Registrazione ok! Ora fai il login."; });
      } else {
        setState(() { _msg = "Errore: ${res.statusCode} - ${res.body}"; });
      }
    } else {
      final res = await http.post(
        Uri.parse("$BASE_URL/utenti.php?action=login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": _username.text, "password": _password.text}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await DBHelper.insert("sessione", {
          "user_id":  data["user_id"],
          "username": _username.text,
          "token":    data["token"],
        });
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => HomeScreen(userId: data["user_id"], username: _username.text),
        ));
      } else {
        setState(() { _msg = "Credenziali non valide."; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isRegister ? "Registrati" : "Login")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _username, decoration: InputDecoration(labelText: "Username")),
            if (_isRegister)
              TextField(controller: _email, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: _password, obscureText: true, decoration: InputDecoration(labelText: "Password")),
            SizedBox(height: 20),
            if (_msg.isNotEmpty) Text(_msg, style: TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _submit,
              child: Text(_isRegister ? "Registrati" : "Login"),
            ),
            TextButton(
              onPressed: () => setState(() { _isRegister = !_isRegister; _msg = ''; }),
              child: Text(_isRegister ? "Hai già un account? Login" : "Nuovo utente? Registrati"),
            ),
          ],
        ),
      ),
    );
  }
}
