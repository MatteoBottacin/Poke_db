**Sviluppatore:** Matteo Bottacin  
**Classe:** 5^IC
---

## Abstract

Poke_db è un'applicazione mobile sviluppata in Flutter con backend in PHP e database MySQL. Permette all'utente di registrarsi, fare il login, sfogliare il Pokédex completo, salvare i Pokémon catturati e gestire la propria squadra da 6 Pokémon. Il server espone API REST complete con metodi GET, POST, PUT, PATCH e DELETE. I dati dei Pokémon vengono recuperati dalla PokeAPI pubblica (`https://pokeapi.co`) tramite il server PHP e salvati nel database locale MySQL. Il client Flutter usa un database locale SQLite come cache offline, così l'app funziona anche senza connessione dopo il primo accesso.

---

## Database MySQL

**Tabella `utenti`**
- `id`, `username`, `password` (hashed), `email`, `token`

**Tabella `pokemon`**
- `id`, `nome`, `url`
- popolata tramite sync con la PokeAPI

**Tabella `pokemon_catturati`**
- `id`, `user_id` (FK), `pokemon_id`, `soprannome`, `livello`, `data_cattura`

**Tabella `squadra`**
- `id`, `pokemon_catturati_id` (FK), `posizione`

---

## API REST

| Endpoint | Metodi | Descrizione |
|---|---|---|
| `utenti.php` | POST | registrazione e login |
| `pokemon.php` | GET | lista pokemon, sync con PokeAPI |
| `catturati.php` | GET, POST, PUT, PATCH, DELETE | gestione pokemon catturati |
| `squadra.php` | GET, POST, PUT, PATCH, DELETE | gestione squadra |

---

## Funzionalità app Flutter

- **Login / Registrazione** — al primo accesso richiede connessione. Salva la sessione in SQLite così gli accessi successivi non richiedono connessione.
- **Pokédex** — mostra i pokemon catturati dall'utente con sprite, soprannome e livello.
- **Aggiungi catturato** — cerca nel DB locale (cache), seleziona il pokemon, assegna soprannome e livello e lo salva sia sul server che in locale.
- **Dettaglio pokemon** — mostra sprite, tipo e statistiche base chiamando direttamente la PokeAPI.
- **Squadra** — permette di comporre una squadra fino a 6 pokemon tra quelli catturati, con possibilità di rimuoverli.
- **Cache offline** — tutte le operazioni salvano i dati in SQLite locale. Se il server non è raggiungibile, i dati vengono letti dalla cache.

---

## Scelte di progetto

- **PHP + MySQLi con Prepared Statements** — scelto MySQLi invece di PDO per semplicità e coerenza con il resto del percorso scolastico. I prepared statements prevengono SQL injection.
- **PokeAPI come sorgente dati** — i dati dei pokemon (nome, sprite, tipi, stats) vengono presi dalla PokeAPI pubblica gratuita, così non serve inserirli a mano nel database.
- **Sync server-side** — il sync della lista pokemon avviene sul server PHP (`pokemon.php?sync=1`) e non direttamente dal client, così il database MySQL ha sempre la lista aggiornata e il client la scarica dal proprio server.
- **SQLite come cache** — scelto `sqflite` per semplicità. Il `DBHelper` è generico e funziona su qualsiasi tabella con le stesse funzioni (`insert`, `getAll`, `getWhere`, `deleteWhere`).
- **Sessione locale** — dopo il primo login il token e lo user_id vengono salvati in SQLite nella tabella `sessione`. All'avvio l'app controlla questa tabella e se trova una sessione salta il login, risolvendo il problema dell'accesso offline.

---

## Diario di progetto

### Step 1 — Progettazione database
Definito lo schema del database con le tabelle `utenti`, `pokemon`, `pokemon_catturati` e `squadra`. Creato il file `poke_db.sql` con le tabelle e i dati di esempio.

### Step 2 — Server PHP
Creati i file PHP per le API REST. Ogni file gestisce un endpoint con switch sul metodo HTTP. Usati prepared statements MySQLi per tutte le operazioni. Aggiunto il sync con la PokeAPI in `pokemon.php?sync=1`.

### Step 3 — Setup Flutter
Installato Flutter, configurato Android Studio con emulatore, create le dipendenze in `pubspec.yaml` (`sqflite`, `path`, `http`).

### Step 4 — Login e sessione
Implementata la schermata di login e registrazione con chiamate HTTP al server. Aggiunta la gestione della sessione locale in SQLite per permettere l'accesso offline dopo il primo login.

### Step 5 — Pokédex e aggiunta pokemon
Implementata la lista dei pokemon catturati e la schermata di aggiunta. La lista pokemon viene scaricata dal server e salvata in cache locale SQLite. Risolto il problema della mappatura `name`→`nome` e dell'estrazione dell'id dall'URL della PokeAPI.

### Step 6 — Dettaglio pokemon
Implementata la schermata di dettaglio che chiama direttamente la PokeAPI per mostrare sprite, tipi e statistiche base.

### Step 7 — Squadra
Implementata la gestione della squadra con limite di 6 pokemon. Aggiunto bottom sheet per la selezione del pokemon da aggiungere. Fix del BASE_URL e della gestione della cache locale.

### Step 8 — Fix e commit finale
Risolti vari bug: soprannome che salvava 0, BASE_URL sbagliato, ricerca non funzionante. Commit finale su GitHub.

