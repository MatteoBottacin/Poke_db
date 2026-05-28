import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DettaglioScreen extends StatefulWidget {
  final int pokemonId;
  const DettaglioScreen({required this.pokemonId});

  @override
  State<DettaglioScreen> createState() => _DettaglioScreenState();
}

class _DettaglioScreenState extends State<DettaglioScreen> {
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _carica();
  }

  void _carica() async {
    final res = await http.get(Uri.parse("https://pokeapi.co/api/v2/pokemon/${widget.pokemonId}"));
    if (res.statusCode == 200) {
      setState(() { _data = jsonDecode(res.body); });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_data == null) return Scaffold(body: Center(child: CircularProgressIndicator()));

    final tipi  = (_data!["types"]  as List).map((t) => t["type"]["name"]).join(", ");
    final stats = (_data!["stats"]  as List);

    return Scaffold(
      appBar: AppBar(title: Text(_data!["name"])),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Image.network(_data!["sprites"]["front_default"], width: 120, height: 120),
            Text("#${_data!["id"]}  ${_data!["name"]}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("Tipo: $tipi"),
            SizedBox(height: 20),
            Text("Statistiche", style: TextStyle(fontWeight: FontWeight.bold)),
            ...stats.map((s) => ListTile(
              title: Text(s["stat"]["name"]),
              trailing: Text("${s["base_stat"]}"),
            )),
          ],
        ),
      ),
    );
  }
}
