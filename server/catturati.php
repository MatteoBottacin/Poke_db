<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE");
header("Access-Control-Allow-Headers: Content-Type");

require_once 'db_config.php';

$method = $_SERVER['REQUEST_METHOD'];
$id     = isset($_GET['id']) ? (int)$_GET['id'] : null;

// legge il body per POST, PUT, PATCH
$body = json_decode(file_get_contents("php://input"), true);

switch($method){

    // GET - lista tutti i catturati o uno specifico
    case 'GET':
        if($id){
            $stmt = mysqli_prepare($conn, "SELECT * FROM pokemon_catturati WHERE id = ?");
            mysqli_stmt_bind_param($stmt, "i", $id);
            mysqli_stmt_execute($stmt);
            $result = mysqli_stmt_get_result($stmt);
            $row = mysqli_fetch_assoc($result);
            if($row){
                echo json_encode($row);
            } else {
                http_response_code(404);
                echo json_encode(["error" => "Pokemon catturato non trovato"]);
            }
            mysqli_stmt_close($stmt);
        } else {
            $user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : null;
            if($user_id){
                $stmt = mysqli_prepare($conn, "SELECT * FROM pokemon_catturati WHERE user_id = ?");
                mysqli_stmt_bind_param($stmt, "i", $user_id);
            } else {
                $stmt = mysqli_prepare($conn, "SELECT * FROM pokemon_catturati");
            }
            mysqli_stmt_execute($stmt);
            $result = mysqli_stmt_get_result($stmt);
            $rows = mysqli_fetch_all($result, MYSQLI_ASSOC);
            echo json_encode($rows);
            mysqli_stmt_close($stmt);
        }
        break;

    // POST - cattura un nuovo pokemon
    case 'POST':
        if(!isset($body['user_id'], $body['pokemon_id'], $body['livello'], $body['data_cattura'])){
            http_response_code(400);
            echo json_encode(["error" => "Campi obbligatori: user_id, pokemon_id, livello, data_cattura"]);
            break;
        }
        $user_id      = $body['user_id'];
        $pokemon_id   = $body['pokemon_id'];
        $soprannome   = $body['soprannome'] ?? null;
        $livello      = $body['livello'];
        $data_cattura = $body['data_cattura'];

        $stmt = mysqli_prepare($conn, "INSERT INTO pokemon_catturati (user_id, pokemon_id, soprannome, livello, data_cattura) VALUES (?, ?, ?, ?, ?)");
        mysqli_stmt_bind_param($stmt, "iiisi", $user_id, $pokemon_id, $soprannome, $livello, $data_cattura);

        if(mysqli_stmt_execute($stmt)){
            http_response_code(201);
            echo json_encode(["message" => "Pokemon catturato!", "id" => mysqli_insert_id($conn)]);
        } else {
            http_response_code(500);
            echo json_encode(["error" => mysqli_error($conn)]);
        }
        mysqli_stmt_close($stmt);
        break;

    // PUT - aggiornamento completo
    case 'PUT':
        if(!$id){
            http_response_code(400);
            echo json_encode(["error" => "ID obbligatorio"]);
            break;
        }
        $soprannome   = $body['soprannome']   ?? null;
        $livello      = $body['livello']      ?? 1;
        $data_cattura = $body['data_cattura'] ?? date('Y-m-d');

        $stmt = mysqli_prepare($conn, "UPDATE pokemon_catturati SET soprannome=?, livello=?, data_cattura=? WHERE id=?");
        mysqli_stmt_bind_param($stmt, "sisi", $soprannome, $livello, $data_cattura, $id);

        if(mysqli_stmt_execute($stmt)){
            echo json_encode(["message" => "Pokemon aggiornato"]);
        } else {
            http_response_code(500);
            echo json_encode(["error" => mysqli_error($conn)]);
        }
        mysqli_stmt_close($stmt);
        break;

    // PATCH - aggiornamento parziale (es. solo soprannome o solo livello)
    case 'PATCH':
        if(!$id){
            http_response_code(400);
            echo json_encode(["error" => "ID obbligatorio"]);
            break;
        }

        $fields = [];
        $types  = "";
        $values = [];

        if(isset($body['soprannome'])){
            $fields[] = "soprannome=?";
            $types   .= "s";
            $values[] = $body['soprannome'];
        }
        if(isset($body['livello'])){
            $fields[] = "livello=?";
            $types   .= "i";
            $values[] = $body['livello'];
        }
        if(isset($body['data_cattura'])){
            $fields[] = "data_cattura=?";
            $types   .= "s";
            $values[] = $body['data_cattura'];
        }

        if(empty($fields)){
            http_response_code(400);
            echo json_encode(["error" => "Nessun campo da aggiornare"]);
            break;
        }

        $values[] = $id;
        $types   .= "i";

        $sql  = "UPDATE pokemon_catturati SET " . implode(", ", $fields) . " WHERE id=?";
        $stmt = mysqli_prepare($conn, $sql);
        mysqli_stmt_bind_param($stmt, $types, ...$values);

        if(mysqli_stmt_execute($stmt)){
            echo json_encode(["message" => "Pokemon aggiornato parzialmente"]);
        } else {
            http_response_code(500);
            echo json_encode(["error" => mysqli_error($conn)]);
        }
        mysqli_stmt_close($stmt);
        break;

    // DELETE - elimina un pokemon catturato
    case 'DELETE':
        if(!$id){
            http_response_code(400);
            echo json_encode(["error" => "ID obbligatorio"]);
            break;
        }
        $stmt = mysqli_prepare($conn, "DELETE FROM pokemon_catturati WHERE id=?");
        mysqli_stmt_bind_param($stmt, "i", $id);

        if(mysqli_stmt_execute($stmt)){
            echo json_encode(["message" => "Pokemon eliminato"]);
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
