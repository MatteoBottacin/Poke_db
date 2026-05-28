<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");

// prende il metodo HTTP
$method = $_SERVER['REQUEST_METHOD'];

if($method === 'GET'){

    // se è stato passato un id o nome chiama la PokeAPI per quel pokemon
    if(isset($_GET['id'])){
        $id = $_GET['id'];
        $url = "https://pokeapi.co/api/v2/pokemon/" . $id;

        $response = file_get_contents($url);

        if($response === false){
            http_response_code(404);
            echo json_encode(["error" => "Pokemon non trovato"]);
            exit;
        }

        $data = json_decode($response, true);

        // restituisce solo i campi utili
        $pokemon = [
            "id"      => $data['id'],
            "name"    => $data['name'],
            "sprite"  => $data['sprites']['front_default'],
            "types"   => array_map(fn($t) => $t['type']['name'], $data['types']),
            "stats"   => array_map(fn($s) => [
                            "name"  => $s['stat']['name'],
                            "value" => $s['base_stat']
                         ], $data['stats'])
        ];

        echo json_encode($pokemon);

    } else {
        // senza id restituisce la lista base (primi 151 pokemon)
        $url = "https://pokeapi.co/api/v2/pokemon?limit=151";
        $response = file_get_contents($url);

        if($response === false){
            http_response_code(500);
            echo json_encode(["error" => "Errore nel contattare la PokeAPI"]);
            exit;
        }

        $data = json_decode($response, true);
        echo json_encode($data['results']);
    }

} else {
    http_response_code(405);
    echo json_encode(["error" => "Metodo non consentito"]);
}
?>
