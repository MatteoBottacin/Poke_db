import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../db_helper.dart';
import 'login_screen.dart';
import 'aggiungi_screen.dart';
import 'dettaglio_screen.dart';

class PokedexScreen extends StatefulWidget {
  final int userId;
  const PokedexScreen({required this.userId});

  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  List<Map<String, dynamic>> _catturati = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carica();
  }

  void _carica() async {
    // prova dal server
    try {
      final res = await http.get(Uri.parse("$BASE_URL/catturati.php?user_id=${widget.userId}"));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        // salva in cache locale
        for (var p in data) {
          await DBHelper.insert("catturati", p);
        }
      }
    } catch (_) {}

    // legge dalla cache locale
    final locale = await DBHelper.getWhere("catturati", "user_id = ?", [widget.userId]);
    setState(() {
      _catturati = locale;
      _loading   = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pokédex")),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => AggiungiScreen(userId: widget.userId),
          ));
          _carica();
        },
        child: Icon(Icons.add),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _catturati.isEmpty
              ? Center(child: Text("Nessun Pokémon catturato"))
              : ListView.builder(
                  itemCount: _catturati.length,
                  itemBuilder: (context, i) {
                    final p = _catturati[i];
                    return ListTile(
                      leading: Image.network(
                        "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${p["pokemon_id"]}.png",
                        width: 50,
                        errorBuilder: (_, __, ___) => Icon(Icons.catching_pokemon),
                      ),
                      title: Text(p["soprannome"] != null && p["soprannome"] != "" ? p["soprannome"] : "Pokemon #${p["pokemon_id"]}"),
                      subtitle: Text("Livello ${p["livello"]}"),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => DettaglioScreen(pokemonId: p["pokemon_id"]),
                      )),
                    );
                  },
                ),
    );
  }
}
