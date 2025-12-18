# fv_spawn

ESX-basiertes Fahrzeug-Spawn-Script für FiveM mit job-basierter Zugriffskontrolle.

## Features

- Automatisches Spawnen von Fahrzeugen an konfigurierten Koordinaten
- Job-basierte Zugriffskontrolle (ab Rang 1)
- Automatisches Respawnen gelöschter Fahrzeuge
- Intelligente Entsperr-Logik bei berechtigten Spielern
- Fahrzeug-Management Commands

## Installation

1. Kopiere den Ordner `fv_spawn` in deinen `resources` Ordner
2. Stelle sicher, dass `es_extended` installiert und gestartet ist
3. Füge `ensure fv_spawn` zu deiner `server.cfg` hinzu

## Konfiguration

### Fahrzeuge hinzufügen

Öffne `client/client.lua` und bearbeite die `coordinate` Tabelle:

```lua
local coordinate = {
  -- Polizei Fahrzeuge 
  -- Straße
  { vector4(-588.71, -383.72, 34.81, 270.52), "polgt63", "police" },
  { vector4(-451.43, -445.36, 33.08, 260.97), "sw_subrb", "police" },
  -- Weitere Fahrzeuge...
}
```

### Format

Jeder Eintrag folgt diesem Format:
```lua
{ vector4(x, y, z, heading), "fahrzeugmodell", "job" }
```

**Parameter:**
- `vector4(x, y, z, heading)`: Koordinaten und Blickrichtung des Fahrzeugs
- `"fahrzeugmodell"`: Spawn-Code des Fahrzeugs (z.B. "polgt63", "sw_subrb")
- `"job"`: Job-Name für Zugriff (z.B. "police", "ambulance")

**Beispiel:**
```lua
{ vector4(-588.71, -383.72, 34.81, 270.52), "polgt63", "police" }
```

Spawnt ein `polgt63` Fahrzeug an den Koordinaten `-588.71, -383.72, 34.81` mit Blickrichtung `270.52` Grad. Nur Spieler mit Job `police` und Rang >= 1 können es nutzen.

## Commands

### /dv

Löscht das Fahrzeug, in dem du sitzt, oder das nächste Fahrzeug in deiner Nähe.

- Am Spawnpunkt (innerhalb von 3m): Fahrzeug wird sofort neu gespawnt
- Nicht am Spawnpunkt: Fahrzeug wird einfach entfernt

### /respawncars

Bringt alle Fahrzeuge für deinen Job zum Spawnpunkt zurück.

**Einstellungen:**
- Cooldown: 30 Minuten
- Verzögerung: 60 Sekunden nach Eingabe
- Besetzte Fahrzeuge werden übersprungen
- Chat-Benachrichtigung informiert alle Spieler

## Zugriffskontrolle

### Job-Anforderung

- Nur Spieler mit dem richtigen Job können die Fahrzeuge nutzen
- Mindestrang: Rang 1 oder höher erforderlich
- Spieler mit falschem Job oder zu niedrigem Rang werden automatisch ausgeworfen

### Entsperr-Mechanismus

- Automatische Entsperrung bei berechtigten Spielern innerhalb von 15 Metern
- Kontinuierliche Prüfung alle 500ms
- Prüfung beim Einsteigen alle 50ms

## Automatisches Respawnen

- Gelöschte Fahrzeuge werden automatisch am Spawnpunkt neu gespawnt
- Prüfung erfolgt alle 5 Sekunden
- Wichtig: Weggefahrene Fahrzeuge werden nicht automatisch gelöscht

## Anpassungen

### Cooldown für /respawncars ändern

In `client/client.lua` Zeile 26:
```lua
local respawnCooldown = 30 * 60 * 1000 -- 30 Minuten in Millisekunden
```

### Verzögerung für /respawncars ändern

In `client/client.lua` Zeile 348:
```lua
Citizen.SetTimeout(60000, function() -- 60 Sekunden = 60000ms
```

### Entsperr-Radius ändern

In `client/client.lua` Zeile 159:
```lua
if distance < 15.0 and data.job == playerJob and playerGrade >= 1 then
```

### Prüfintervalle anpassen

- Kontinuierliche Prüfung: Zeile 143 (`Wait(500)`)
- Prüfung beim Einsteigen: Zeile 95 (`Wait(50)`)
- Automatisches Respawnen: Zeile 238 (`Wait(5000)`)

## Fehlerbehebung

### Fahrzeuge werden nicht gespawnt

- Prüfe, ob die Fahrzeugmodelle auf dem Server vorhanden sind
- Stelle sicher, dass die Koordinaten korrekt sind
- Überprüfe die Konsole auf Fehlermeldungen

### Fahrzeuge können nicht genutzt werden

- Prüfe, ob der Spieler den richtigen Job hat
- Stelle sicher, dass der Spieler mindestens Rang 1 hat
- Überprüfe, ob `es_extended` korrekt läuft

### Fahrzeuge werden nicht entsperrt

- Prüfe die Distanz zum Fahrzeug (muss < 15m sein)
- Stelle sicher, dass der Job-Name exakt übereinstimmt (Groß-/Kleinschreibung beachten)
- Überprüfe, ob ESX korrekt geladen ist

## Abhängigkeiten

- es_extended (ESX Framework) - erforderlich

## Autor

dias

## Version

1.0.0

## Lizenz

Dieses Script ist für den privaten Gebrauch bestimmt. Weitergabe und Modifikation sind erlaubt.

---

**Hinweis:** Dieses Script ist speziell für ESX entwickelt. Für andere Frameworks sind Anpassungen erforderlich.
