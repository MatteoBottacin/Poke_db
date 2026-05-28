import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../db_helper.dart';
import 'login_screen.dart';

class AggiungiScreen extends StatefulWidget {
  final int userId;
  const AggiungiScreen({required this.userId});

  @override
  State<AggiungiScreen> createState() => _AggiungiScreenState();
}

class _AggiungiScreenState extends State<AggiungiScreen> {
  List<Map<String, dynamic>> _pokemon  = [];
  List<Map<String, dynamic>> _filtrati = [];
  Map<String, dynamic>? _selezionato;
  final _soprannome = TextEditingController();
  final _livello    = TextEditingController(text: "1");
  final _search     = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carica();
  }

  void _carica() async {
    final locale = await DBHelper.getAll("pokemon");
    if (locale.isNotEmpty) {
      setState(() { _pokemon = locale; _filtrati = locale; });
    } else {
      final res = await http.get(Uri.parse("$BASE_URL/pokemon.php"));
      final List data = jsonDecode(res.body);
      List<Map<String, dynamic>> lista = [];
      for (var p in data) {
        final parts = (p["url"] as String).split("/");
        final pokemonId = int.parse(parts[parts.length - 2]);
        final item = {"id": pokemonId, "nome": p["name"], "url": p["url"]};
        await DBHelper.insert("pokemon", item);
        lista.add(item);
      }
      setState(() { _pokemon = lista; _filtrati = lista; });
    }
  }

  void _cerca(String q) {
    setState(() {
      _filtrati = _pokemon
          .where((p) => p["nome"].toString().toLowerCase().contains(q.toLowerCase()))
          .toList();
    });
  }

  void _salva() async {
    if (_selezionato == null) return;
    final body = {
      "user_id":      widget.userId,
      "pokemon_id":   _selezionato!["id"],
      "soprannome":   _soprannome.text.trim(),
      "livello":      int.tryParse(_livello.text.trim()) ?? 1,
      "data_cattura": DateTime.now().toIso8601String().substring(0, 10),
    };
    try {
      final res = await http.post(
        Uri.parse("$BASE_URL/catturati.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      if (res.statusCode == 201) {
        final risposta = jsonDecode(res.body);
        await DBHelper.insert("catturati", {...body, "id": risposta["id"]});
      }
    } catch (_) {
      await DBHelper.insert("catturati", {...body, "id": DateTime.now().millisecondsSinceEpoch});
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Aggiungi Catturato")),
      body: _pokemon.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              controller: _search,
              onChanged: _cerca,
              decoration: InputDecoration(
                labelText: "Cerca Pokémon",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          if (_selezionato != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Text("Selezionato: ${_selezionato!["nome"]}", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _soprannome,
                    decoration: InputDecoration(labelText: "Soprannome (facoltativo)"),
                  ),
                  TextField(
                    controller: _livello,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "Livello"),
                  ),
                  ElevatedButton(onPressed: _salva, child: Text("Aggiungi")),
                ],
              ),
            ),
          ],
          Expanded(
            child: ListView.builder(
              itemCount: _filtrati.length,
              itemBuilder: (context, i) {
                final p = _filtrati[i];
                return ListTile(
                  leading: Image.network(
                    "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${p["id"]}.png",
                    width: 40,
                    errorBuilder: (_, __, ___) => Icon(Icons.catching_pokemon),
                  ),
                  title: Text(p["nome"]),
                  subtitle: Text("#${p["id"]}"),
                  selected: _selezionato?["id"] == p["id"],
                  onTap: () {
                    setState(() {
                      _selezionato = p;
                      _soprannome.clear();
                      _livello.text = "1";
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}