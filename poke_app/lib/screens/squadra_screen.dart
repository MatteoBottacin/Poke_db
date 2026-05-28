import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../db_helper.dart';
import 'login_screen.dart';
import 'dettaglio_screen.dart';

class SquadraScreen extends StatefulWidget {
  final int userId;
  const SquadraScreen({required this.userId});

  @override
  State<SquadraScreen> createState() => _SquadraScreenState();
}

class _SquadraScreenState extends State<SquadraScreen> {
  List<Map<String, dynamic>> _squadra = [];
  List<Map<String, dynamic>> _catturati = [];

  var isConnected = true;
  @override
  void initState() {
    super.initState();
    _carica();
  }

  void _carica() async {
    var result = await Connectivity().checkConnectivity();
    setState(() {
      isConnected = result[0] != ConnectivityResult.none;
    });

    final squadra = await DBHelper.getAll("squadra");
    final catturati =
        await DBHelper.getWhere("catturati", "user_id = ?", [widget.userId]);
    setState(() {
      _squadra = squadra;
      _catturati = catturati;
    });
  }

  void _aggiungi() async {
    if (_squadra.length >= 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Squadra piena (max 6)")));
      return;
    }

    final inSquadra = _squadra.map((s) => s["pokemon_catturati_id"]).toSet();
    final disponibili =
        _catturati.where((c) => !inSquadra.contains(c["id"])).toList();

    if (disponibili.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Nessun Pokémon disponibile")));
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.builder(
        itemCount: disponibili.length,
        itemBuilder: (context, i) {
          final p = disponibili[i];
          final nome = (p["soprannome"] != null && p["soprannome"] != "")
              ? p["soprannome"]
              : "Pokemon #${p["pokemon_id"]}";
          return ListTile(
            leading: Image.network(
              "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${p["pokemon_id"]}.png",
              width: 40,
              errorBuilder: (_, __, ___) => Icon(Icons.catching_pokemon),
            ),
            title: Text(nome),
            subtitle: Text("Livello ${p["livello"]}"),
            onTap: () async {
                Navigator.pop(context);
                final posizione = _squadra.length + 1;
                final body = {
                  "pokemon_catturati_id": p["id"],
                  "posizione": posizione
                };
                try {
                  final res = await http.post(
                    Uri.parse("$BASE_URL/squadra.php"),
                    headers: {"Content-Type": "application/json"},
                    body: jsonEncode(body),
                  );
                  if (res.statusCode == 201) {
                    final risposta = jsonDecode(res.body);
                    await DBHelper.insert(
                        "squadra", {...body, "id": risposta["id"]});
                  }
                } catch (_) {
                  await DBHelper.insert("squadra",
                      {...body, "id": DateTime.now().millisecondsSinceEpoch});
                }
                _carica();
              
            },
          );
        },
      ),
    );
  }

  void _rimuovi(int id) async {
    try {
      await http.delete(Uri.parse("$BASE_URL/squadra.php?id=$id"));
    } catch (_) {}
    await DBHelper.deleteWhere("squadra", "id = ?", [id]);
    _carica();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Squadra (${_squadra.length}/6)")),
      floatingActionButton: isConnected?  FloatingActionButton(
        onPressed: _aggiungi,
        child: Icon(Icons.add),
      ):null,
      body: _squadra.isEmpty
          ? Center(child: Text("Squadra vuota, premi + per aggiungere"))
          : ListView.builder(
              itemCount: _squadra.length,
              itemBuilder: (context, i) {
                final s = _squadra[i];
                final catturato = _catturati.firstWhere(
                  (c) => c["id"] == s["pokemon_catturati_id"],
                  orElse: () => <String, dynamic>{},
                );
                final pokemonId = catturato["pokemon_id"] ?? 0;
                final nome = (catturato["soprannome"] != null &&
                        catturato["soprannome"] != "")
                    ? catturato["soprannome"]
                    : "Pokemon #$pokemonId";
                return ListTile(
                  leading: Image.network(
                    "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$pokemonId.png",
                    width: 50,
                    errorBuilder: (_, __, ___) => Icon(Icons.catching_pokemon),
                  ),
                  title: Text(nome),
                  subtitle: Text(
                      "Posizione ${s["posizione"]}  •  Livello ${catturato["livello"] ?? "?"}"),
                  trailing: isConnected ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.info_outline),
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DettaglioScreen(pokemonId: pokemonId),
                            )),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _rimuovi(s["id"]),
                      ),
                    ],
                  ):null,
                );
              },
            ),
    );
  }
}
