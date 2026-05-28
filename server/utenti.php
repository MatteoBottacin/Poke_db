<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, DELETE");
header("Access-Control-Allow-Headers: Content-Type");

require_once 'db_config.php';

$method = $_SERVER['REQUEST_METHOD'];
$body   = json_decode(file_get_contents("php://input"), true);
$action = isset($_GET['action']) ? $_GET['action'] : null;

switch($method){

    // GET - prende un utente tramite token
    case 'GET':
        $token = isset($_GET['token']) ? $_GET['token'] : null;
        if(!$token){
            http_response_code(400);
            echo json_encode(["error" => "Token obbligatorio"]);
            break;
        }
        $stmt = mysqli_prepare($conn, "SELECT id, username, email FROM utenti WHERE token=?");
        mysqli_stmt_bind_param($stmt, "s", $token);
        mysqli_stmt_execute($stmt);
        $result = mysqli_stmt_get_result($stmt);
        $row = mysqli_fetch_assoc($result);
        if($row){
            echo json_encode($row);
        } else {
            http_response_code(404);
            echo json_encode(["error" => "Utente non trovato"]);
        }
        mysqli_stmt_close($stmt);
        break;

    case 'POST':

        // registrazione
        if($action === 'register'){
            if(!isset($body['username'], $body['password'], $body['email'])){
                http_response_code(400);
                echo json_encode(["error" => "Campi obbligatori: username, password, email"]);
                break;
            }
            $username = $body['username'];
            $password = password_hash($body['password'], PASSWORD_DEFAULT);
            $email    = $body['email'];

            $stmt = mysqli_prepare($conn, "INSERT INTO utenti (username, password, email) VALUES (?, ?, ?)");
            mysqli_stmt_bind_param($stmt, "sss", $username, $password, $email);

            if(mysqli_stmt_execute($stmt)){
                http_response_code(201);
                echo json_encode(["message" => "Registrazione completata"]);
            } else {
                http_response_code(500);
                echo json_encode(["error" => mysqli_error($conn)]);
            }
            mysqli_stmt_close($stmt);

        // login
        } elseif($action === 'login'){
            if(!isset($body['username'], $body['password'])){
                http_response_code(400);
                echo json_encode(["error" => "Campi obbligatori: username, password"]);
                break;
            }
            $username = $body['username'];

            $stmt = mysqli_prepare($conn, "SELECT id, password FROM utenti WHERE username=?");
            mysqli_stmt_bind_param($stmt, "s", $username);
            mysqli_stmt_execute($stmt);
            $result = mysqli_stmt_get_result($stmt);
            $row = mysqli_fetch_assoc($result);
            mysqli_stmt_close($stmt);

            if($row && password_verify($body['password'], $row['password'])){
                // genera token e lo salva
                $token = bin2hex(random_bytes(32));
                $stmt2 = mysqli_prepare($conn, "UPDATE utenti SET token=? WHERE id=?");
                mysqli_stmt_bind_param($stmt2, "si", $token, $row['id']);
                mysqli_stmt_execute($stmt2);
                mysqli_stmt_close($stmt2);
                echo json_encode(["message" => "Login effettuato", "token" => $token, "user_id" => $row['id']]);
            } else {
                http_response_code(401);
                echo json_encode(["error" => "Credenziali non valide"]);
            }

        } else {
            http_response_code(400);
            echo json_encode(["error" => "Action non valida. Usa: register o login"]);
        }
        break;

    // DELETE - elimina account
    case 'DELETE':
        $id = isset($_GET['id']) ? (int)$_GET['id'] : null;
        if(!$id){
            http_response_code(400);
            echo json_encode(["error" => "ID obbligatorio"]);
            break;
        }
        $stmt = mysqli_prepare($conn, "DELETE FROM utenti WHERE id=?");
        mysqli_stmt_bind_param($stmt, "i", $id);

        if(mysqli_stmt_execute($stmt)){
            echo json_encode(["message" => "Utente eliminato"]);
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
