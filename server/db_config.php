<?php
$conn = mysqli_connect("localhost", "root", "", "poke_db");
if($conn === false){
    exit("Errore: impossibile stabilire una connessione " . mysqli_connect_error());
}
mysqli_set_charset($conn, "utf8");
?>
