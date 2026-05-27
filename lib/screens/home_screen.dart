import 'package:flutter/material.dart';
import '../db_helper.dart';
import 'login_screen.dart';
import 'pokedex_screen.dart';
import 'squadra_screen.dart';

class HomeScreen extends StatelessWidget {
  final int userId;
  final String username;
  const HomeScreen({required this.userId, required this.username});

  void _logout(BuildContext context) async {
    await DBHelper.deleteWhere("sessione", "1=1", []);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ciao $username!"),
        actions: [
          IconButton(icon: Icon(Icons.logout), onPressed: () => _logout(context)),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => PokedexScreen(userId: userId),
              )),
              child: Text("Pokédex"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => SquadraScreen(userId: userId),
              )),
              child: Text("Squadra"),
            ),
          ],
        ),
      ),
    );
  }
}
