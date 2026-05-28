import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../db_helper.dart';
import 'home_screen.dart';

const String BASE_URL = "http://10.236.86.247/poke-api";

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var username  = TextEditingController();
  var password  = TextEditingController();
  var email     = TextEditingController();
  bool isRegister = false;
  String msg      = '';

  @override
  void initState() {
    super.initState();
    checkSessione();
  }

  // se c'è già una sessione salvata vai direttamente alla home
  void checkSessione() async {
    var sessioni = await DBHelper.getAll("sessione");
    if (sessioni.isNotEmpty) {
      var s = sessioni.last;
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => HomeScreen(userId: s["user_id"], username: s["username"]),
      ));
    }
  }

  void submit() async {
    if (isRegister) {
      var res = await http.post(
        Uri.parse("$BASE_URL/utenti.php?action=register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username.text, "password": password.text, "email": email.text}),
      );
      if (res.statusCode == 201) {
        setState(() { isRegister = false; msg = "Registrazione ok! Ora fai il login."; });
      } else {
        setState(() { msg = "Errore: ${res.statusCode} - ${res.body}"; });
      }
    } else {
      var res = await http.post(
        Uri.parse("$BASE_URL/utenti.php?action=login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username.text, "password": password.text}),
      );
      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        await DBHelper.insert("sessione", {
          "user_id":  data["user_id"],
          "username": username.text,
          "token":    data["token"],
        });
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => HomeScreen(userId: data["user_id"], username: username.text),
        ));
      } else {
        setState(() { msg = "Credenziali non valide."; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isRegister ? "Registrati" : "Login")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: username, decoration: InputDecoration(labelText: "Username")),
            if (isRegister)
              TextField(controller: email, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: password, obscureText: true, decoration: InputDecoration(labelText: "Password")),
            SizedBox(height: 20),
            if (msg.isNotEmpty) Text(msg, style: TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: submit,
              child: Text(isRegister ? "Registrati" : "Login"),
            ),
            TextButton(
              onPressed: () => setState(() { isRegister = !isRegister; msg = ''; }),
              child: Text(isRegister ? "Hai già un account? Login" : "Nuovo utente? Registrati"),
            ),
          ],
        ),
      ),
    );
  }
}
