<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE");
header("Access-Control-Allow-Headers: Content-Type");

require_once 'db_config.php';

$method = $_SERVER['REQUEST_METHOD'];
$id     = isset($_GET['id']) ? (int)$_GET['id'] : null;
$body   = json_decode(file_get_contents("php://input"), true);

switch($method){

    // GET - mostra la squadra (con JOIN per avere i dettagli del pokemon catturato)
    case 'GET':
        $stmt = mysqli_prepare($conn,
            "SELECT s.id, s.posizione, pc.pokemon_id, pc.soprannome, pc.livello
             FROM squadra s
             JOIN pokemon_catturati pc ON s.pokemon_catturati_id = pc.id
             ORDER BY s.posizione ASC"
        );
        mysqli_stmt_execute($stmt);
        $result = mysqli_stmt_get_result($stmt);
        $rows = mysqli_fetch_all($result, MYSQLI_ASSOC);
        echo json_encode($rows);
        mysqli_stmt_close($stmt);
        break;

    // POST - aggiunge un pokemon alla squadra
    case 'POST':
        if(!isset($body['pokemon_catturati_id'], $body['posizione'])){
            http_response_code(400);
            echo json_encode(["error" => "Campi obbligatori: pokemon_catturati_id, posizione"]);
            break;
        }
        $pokemon_catturati_id = $body['pokemon_catturati_id'];
        $posizione            = $body['posizione'];

        $stmt = mysqli_prepare($conn, "INSERT INTO squadra (pokemon_catturati_id, posizione) VALUES (?, ?)");
        mysqli_stmt_bind_param($stmt, "ii", $pokemon_catturati_id, $posizione);

        if(mysqli_stmt_execute($stmt)){
            http_response_code(201);
            echo json_encode(["message" => "Pokemon aggiunto alla squadra", "id" => mysqli_insert_id($conn)]);
        } else {
            http_response_code(500);
            echo json_encode(["error" => mysqli_error($conn)]);
        }
        mysqli_stmt_close($stmt);
        break;

    // PUT - aggiornamento completo (cambia pokemon e posizione)
    case 'PUT':
        if(!$id){
            http_response_code(400);
            echo json_encode(["error" => "ID obbligatorio"]);
            break;
        }
        $pokemon_catturati_id = $body['pokemon_catturati_id'];
        $posizione            = $body['posizione'];

        $stmt = mysqli_prepare($conn, "UPDATE squadra SET pokemon_catturati_id=?, posizione=? WHERE id=?");
        mysqli_stmt_bind_param($stmt, "iii", $pokemon_catturati_id, $posizione, $id);

        if(mysqli_stmt_execute($stmt)){
            echo json_encode(["message" => "Squadra aggiornata"]);
        } else {
            http_response_code(500);
            echo json_encode(["error" => mysqli_error($conn)]);
        }
        mysqli_stmt_close($stmt);
        break;

    // PATCH - aggiornamento parziale (es. cambia solo la posizione)
    case 'PATCH':
        if(!$id){
            http_response_code(400);
            echo json_encode(["error" => "ID obbligatorio"]);
            break;
        }

        $fields = [];
        $types  = "";
        $values = [];

        if(isset($body['posizione'])){
            $fields[] = "posizione=?";
            $types   .= "i";
            $values[] = $body['posizione'];
        }
        if(isset($body['pokemon_catturati_id'])){
            $fields[] = "pokemon_catturati_id=?";
            $types   .= "i";
            $values[] = $body['pokemon_catturati_id'];
        }

        if(empty($fields)){
            http_response_code(400);
            echo json_encode(["error" => "Nessun campo da aggiornare"]);
            break;
        }

        $values[] = $id;
        $types   .= "i";

        $sql  = "UPDATE squadra SET " . implode(", ", $fields) . " WHERE id=?";
        $stmt = mysqli_prepare($conn, $sql);
        mysqli_stmt_bind_param($stmt, $types, ...$values);

        if(mysqli_stmt_execute($stmt)){
            echo json_encode(["message" => "Squadra aggiornata parzialmente"]);
        } else {
            http_response_code(500);
            echo json_encode(["error" => mysqli_error($conn)]);
        }
        mysqli_stmt_close($stmt);
        break;

    // DELETE - rimuove un pokemon dalla squadra
    case 'DELETE':
        if(!$id){
            http_response_code(400);
            echo json_encode(["error" => "ID obbligatorio"]);
            break;
        }
        $stmt = mysqli_prepare($conn, "DELETE FROM squadra WHERE id=?");
        mysqli_stmt_bind_param($stmt, "i", $id);

        if(mysqli_stmt_execute($stmt)){
            echo json_encode(["message" => "Pokemon rimosso dalla squadra"]);
        } else {
            http_response_code(500);
            echo json_encode(["error" => mysqli_error($conn)]);
        }
        mysqli_stmt_close($stmt);
        break;

    default:
        http_response_code(405);
        echo json_encode(["error" => "Metodo non consentito"]);
}

mysqli_close($conn);
?>
