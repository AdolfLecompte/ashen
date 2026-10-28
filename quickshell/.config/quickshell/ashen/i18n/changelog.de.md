# Änderungen

Übersetzung der Notizen aus CHANGELOG.md. Nur die aktuelle Version wird
gebraucht: fehlt sie, zeigt die Begrüßung die englischen Notizen.

## 3.7.0

### Hinzugefügt
- **Hängend**, ein Leistenstil: eine Platte, die vom Bildschirmrand hängt,
  gerade, wo sie ihn berührt, nach innen gerundet, und der Rand biegt sich
  in beide Enden hinein. Die Längeneinstellung gilt weiter.
- **Fenster per Tastatur anordnen.** `SUPER+SHIFT+Pfeile` verschiebt ein
  Fenster (auch in Gruppen hinein und heraus), `SUPER+J`/`SUPER+K` drehen
  und tauschen eine Teilung, `SUPER+R` schaltet durch 1/3, 1/2 und 2/3, und
  `SUPER+CTRL+P` heftet es an alle Arbeitsflächen.
- **Tabs**: `SUPER+G` gruppiert Fenster als Tabs, `SUPER+Tab` und
  `SUPER+SHIFT+Tab` wechseln zwischen ihnen. Die Tableiste trägt die
  Akzentfarbe des Hintergrunds.
- **Spalten**: `SUPER+SHIFT+L` wechselt die Arbeitsfläche zwischen Kacheln
  und dem Spaltenlayout, bis Hyprland neu lädt.
- Schwebende Fenster rasten an Rändern und aneinander ein.
- **Tooltips** an reinen Symbol-Schaltflächen nach kurzer Pause, und eine
  Welle von der Stelle, an der du drückst.
- **Privatsphäre-Anzeige**: eine Pille zeigt Mikrofon, Kamera und
  Bildschirm, solange etwas sie nutzt.
- **Abgerundete Bildschirmecken**, unter Einstellungen > Anzeige.
- `ashen rollback` kehrt dorthin zurück, wo das letzte `ashen update` begann.
- **Tageslimits** im Bildschirmzeit-Panel: die Sanduhr in der Zeile einer
  App schaltet durch 30 Min., 1, 2 und 3 Stunden. Ein Hinweis kommt fünf
  Minuten vorher und wenn die Zeit um ist.
- **Hooks**: eine ausführbare Datei unter `~/.config/ashen/hooks/<Ereignis>`
  läuft bei startup, wallpaper, lock, unlock, theme, power, battery-low, usb
  und game. Mehr im README.
- **Tasten in Panels**: Escape schließt sie; die Pfeile ändern Lautstärke,
  Tag oder Titel, Leertaste spielt und pausiert, M schaltet stumm, und
  `Strg+Tab` geht durch die Tabs der Einstellungen.

### Geändert
- `SUPER+SHIFT+F` lässt ein Fenster zentriert bei 60 % mal 70 % schweben
  und hebt vorher die Maximierung auf.
- Das Bildschirmzeit-Panel spricht die Sprache des Uhr-Panels: keine
  Platten, Haarlinien zwischen den Bereichen, App-Zeilen wie im Widget und
  eine Stundenkurve, skaliert auf die vollste Stunde. Ein Tageswechsel
  gleitet in die Richtung, in die du gehst, dann wachsen Kurve und Balken;
  eine neue Woche hebt alle Balken, ein neuer Tag nur seinen.
- Der Blur-Stil ist gläserner: ein dünnerer Schleier auf Leiste, Panels,
  Pillen und Widgets, und ein Compositor-Blur, der das Dahinter nicht mehr
  abdunkelt (Fenster eingeschlossen).
- Einstellungen > Netzwerk besteht aus Karten; das Passwort öffnet sich
  unter seinem Netz, statt die Seite zu verdecken.
- Die Bearbeitungsleiste des Desktops sind Symbole mit benanntem Modus,
  die Widget-Auswahl ist gruppiert, mit Haken statt Akzentfüllung.
- Die Hintergrundauswahl öffnet etwa doppelt so schnell.
- Der Musikfortschritt ist eine Welle, die beim Abspielen wandert und in
  der Pause flach wird.
- Fenster öffnen und bewegen sich mit einer ausschwingenden Feder; der
  Spezial-Arbeitsbereich dunkelt ab, was dahinter liegt.
- Tastaturlayouts und die Farbe des Fensterrahmens liegen in
  `~/.config/ashen/hypr/`, außerhalb des Checkouts, und eine `user.lua` dort
  nimmt deine eigene Hyprland-Konfiguration auf, zuletzt geladen. Updates
  stoßen nicht mehr mit ihnen zusammen.

### Behoben
- App-Symbole im Dock, in den Einstellungen und im Starter sind scharf;
  sie waren verpixelt und im Dock beim Überfahren noch unschärfer.
- Ein polkit-Agent startet mit der Sitzung; Apps, die root brauchten,
  konnten nicht fragen.
- Dockers virtuelle Ports erscheinen nicht mehr im Ethernet-Panel.
- Die Anzeige für Lautstärke und Helligkeit war bei rechter Leiste
  abgeschnitten und flackerte beim Ausblenden.
- Einstellungen werden in einem Schritt geschrieben; ein Absturz beim
  Speichern lässt sie nicht mehr leer zurück.
- Wetter für eine Stadt mit Apostroph im Namen (L'Aquila).
- Eine Fensterklasse oder Benachrichtigung mit Anführungszeichen konnte
  über das Dock oder die Fokus-Aktion Befehle ausführen.
- Kamera-Anzeige und Tastaturlayout kosten im Leerlauf weniger.

## 3.6.0

### Neu
- **Das Dock trägt mehr als Apps.** Einstellungen > Desktop > Dock setzt
  Kapseln der Leiste als Symbole hinein -- Ton, Akku, die Uhr,
  Benachrichtigungen und der Rest, jede tut, was ihre Kapsel tut -- und
  Verknüpfungen: Sperren, Hintergründe, Einstellungen, Prozesse, Widgets
  anordnen, Spielmodus, Nachtlicht oder ein eigener Befehl mit Symbol.
  Jede Gruppe steht vor oder nach den Apps. Ein
  Rechtsklick nimmt eine heraus, so wie er eine App löst.
- **Angedockt**, ein Leistenstil: bündig am ganzen Rand, ohne Luft drumherum,
  und der Bildschirm wölbt sich an beiden Enden in sie hinein.
- Kleinigkeiten zum Anklicken auf den Widgets, auf dem Desktop und dem
  Sperrbildschirm: die Musikkarte klappt die gerade gesungene Zeile aus, die
  Benachrichtigungskarte klappt für mehr auf (oder für ein kleines
  Pixelbild, wenn nichts da ist), und wer der Rechnerkarte nahe kommt, sieht
  den Akku und wie lange er noch hält. Das große Musik-Widget öffnet seinen
  Liedtext daneben.
- Die Suchergebnisse der Einstellungen tragen das Symbol ihres Abschnitts
  und sagen, wo sie wohnen, wenn zwei gleich heißen.
- **Der Befehl `ashen`**: `update`, `check`, `version`, `restart`, `doctor`,
  `logs`, `wallpaper next|prev|random|<Datei>`, `bar …` und `ipc …`, mit
  zsh-Vervollständigung (`ashen help`).
- Ein Toast meldet, wenn sich Tastaturlayout, Sprache der Shell oder die
  Stadt fürs Wetter ändern.

### Geändert
- **Framed ist weg**; Angedockt tritt an seine Stelle, und gespeicherte
  Looks, die es nutzten, laden als Angedockt.
- Die Karten der Einstellungen tragen ihr Symbol und einen Titel, der die
  Zeilen darunter anführt.
- Die Bildauswahl spricht die Sprache der Panels: Symbolkacheln, Orte auf
  einer Platte, Ordner als Zeilen.
- Die Klangwelle der Leiste wird hinter Fenstern und Widgets gezeichnet und
  reicht weiter in den Bildschirm.
- Die Welle des Visualisierers und der Streifen des Musik-Widgets sind
  dichter.
- Das Dock mit automatischem Ausblenden macht sich Platz wie die Leiste.
- Wetterort und Tastaturlayouts sind jetzt Listen, mit dem Suchfeld der
  Einstellungen darunter: Treffer klappen im selben Feld auf, Enter nimmt
  den ersten, und ein Fehlgriff sagt es an Ort und Stelle.

### Behoben
- **Die Shell verbrauchte im Leerlauf ein paar Prozent CPU.** Sie lauschte
  mit `powerprofilesctl monitor` auf Energieprofile, einem Befehl, den
  neuere Versionen entfernt haben: er beendete sich sofort und wurde
  mehrmals pro Sekunde neu gestartet, endlos. Das Profil wird jetzt direkt
  vom Dienst gelesen, und der Leerlauf liegt wieder weit unter einem halben
  Prozent.
- **Aktualisieren aktualisiert jetzt.** Der Knopf ließ den Installer über
  den vorhandenen Code laufen und holte nie die neue Version; jetzt führt er
  `ashen update` aus, das zuerst herunterlädt.
- Desktop-Widgets verschwinden nicht mehr hinter einem maximierten (nicht
  Vollbild-) Fenster.
- Eine angeheftete App in Einstellungen > Desktop zu ziehen hinterlässt
  keine kaputte Zeile mehr.
- Der Hover des Profilbilds franst seinen runden Rand nicht mehr aus.
- Das Hintergrundbild oben in Aussehen lädt nicht mehr bei jedem Besuch neu.
- Hintergrundauswahl, Alt+Tab und Ausschaltmenü öffnen und schließen nicht
  mehr hinter einer harten Kante quer durch sie; das Karussell der Auswahl
  blendet aus, statt in einem Frame zu verschwinden.
- Die angehefteten Apps des Docks in den Einstellungen umzusortieren
  brauchte zwei Züge: die Liste behielt nach dem ersten die alte Reihenfolge,
  und der nächste Klick erwischte die falsche Zeile.
- Widgets, die aufklappen (Musik, Benachrichtigungen, der Rechner), zittern
  auf dem Sperrbildschirm nicht mehr und schieben die Karten darunter nicht
  mehr ruckweise: die Platte gleitet einmal, auf ihre Endgröße. Und die
  Spalten des Sperrbildschirms springen nicht mehr auf und ab, während eine
  aufklappt: ihre Höhe wird erst gemessen, wenn die Falte stillsteht.

## 3.5.0

### Neu
- **Touchpad-Gesten und ein Scratchpad** (Ideen aus RchrdArizas PR #2).
  Drei Finger seitlich wechseln weiter die Arbeitsfläche; nach oben öffnet
  den Starter, nach unten das Scratchpad; vier Finger verschieben das
  Fenster. Sie stehen in `hypr/conf/gestures.lua`, Einstellungen > Eingabe
  listet sie. SUPER+S zeigt das Scratchpad, SUPER+ALT+S schickt ein Fenster
  hin (beide neu belegbar); sein Chip zeigt das Symbol der App darin.

### Geändert
- Neuigkeiten zeigt die letzten drei Versionen, jede unter ihrer Nummer,
  nicht nur die laufende: eine kleine Version wirkte wie abgeschnitten.

### Danke
- **@RchrdAriza** für die Touchpad-Gesten, das Scratchpad und sein
  Live-Symbol (PR #2), auf denen diese Version aufbaut.

## 3.4.0

### Neu
- **Ashen sagt Bescheid, wenn eine neue Version erscheint.** Eine Minute
  nach dem Anmelden und danach alle sechs Stunden prüft es das neueste
  Release auf GitHub (nie einen Commit) und zeigt einmal pro Version eine
  Toast (Version und ein Satz aus dem Phrasenvorrat) mit Aktualisieren. Er
  bleibt doppelt so lange wie andere Toasts und landet im
  Benachrichtigungsverlauf, falls du ihn verpasst. Still ohne Netz, wenn
  aktuell oder voraus. Der Schalter ist unter Einstellungen > Über.
- **Wähle, welchem Player die Musikkarte folgt**, wie in Caelestia: der
  Name des Players steht zwischen den Zeiten, ein Klick listet alle Player mit
  dem, was sie spielen; die Wahl übernehmen Karte, Tasten, Leiste und Widgets
  (`qs -c ashen ipc call media source` springt zum nächsten). Vorher nahm
  jede Fläche den ersten, der andere ließ sich nicht pausieren. Zwei Tabs
  eines Browsers bleiben ein Player: der Browser meldet nur den letzten.
- **Liedtext ist ein eigenes Widget**, keine Form des Musik-Widgets mehr:
  den Text zu lesen kostete die Wiedergabetaste. Drei Formen -- *Seite* (die
  alte, mit Cover), *Zeile* (die gesungene Zeile und die nächste, für eine
  Ecke) und *Fokus* (die Zeile groß in der Mitte, die umliegenden gedämpft).
  Ein Desktop mit der Liedtext-Form bekommt das Liedtext-Widget an ihre
  Stelle.
- Der Sperrbildschirm zeigt die Musikwelle an seinem oberen Rand, im Ruhezustand
  und beim Anmelden -- dieselbe, die die Leiste zeichnet.
- **Der Installer fragt zuerst drei Dinge**, mit den Pfeiltasten: die
  Sprache der Shell, das Tastaturlayout (es gilt auch am Anmeldebildschirm)
  und die Systemsprache (`locale-gen` + `localectl`; die aktuelle zu behalten
  ist die Vorgabe). `ASHEN_LANG`, `ASHEN_KB` und `ASHEN_LOCALE` überspringen
  jeweils eine Frage.
- Begrüßung und Versionshinweise kommen in deiner Sprache: die spanischen,
  deutschen und russischen liegen in `i18n/changelog.<sprache>.md`, sonst
  Englisch.

### Geändert
- **Das USB-Panel, neu gemacht.** Eine Karte pro Laufwerk mit seinen
  Partitionen darin, statt einer pro Partition mit je einer Auswerfen-Taste.
  Jede Partition hat Ordner öffnen und Ein-/Aushängen, eingehängt einen
  Balken mit dem freien Platz; das Laufwerk hat Auswerfen, das alles aushängt
  und es abschaltet. Jede Aktion wartet auf ihre Antwort und sagt sie. Auch
  externe USB-Festplatten erscheinen. `qs -c ashen ipc call usb toggle|state`.
- **Panels öffnen sich in einer Bewegung aus ihrer Pille.** Im
  Verwandlungsstil fällt ein Panel nicht mehr an einem Faden aus der Leiste:
  es dehnt sich aus seiner Pille und bleibt an ihr, in der Farbe der Leiste,
  sodass es wie die wachsende Leiste wirkt. Beim Schließen setzt es weich auf
  der Pille auf, die erscheint, sobald die Box ankommt. Funktioniert an jedem
  Rand. `qs -c ashen ipc call panels style morph|plain` schaltet es um.
- Angeheftete Dock-Apps werden per Ziehen sortiert (Einstellungen >
  Desktop > Dock) und gelöst, indem man sie auf die Zone fallen lässt, die
  beim Ziehen an die Stelle des Suchfelds tritt. Keine Pfeile mehr.
- **System beginnt mit dir**: dein Bild groß über deinem Hintergrund,
  unscharf, mit deinem Namen und einer Taste zum Ändern.
- **Leerlauf & Ruhezustand** auf einen Blick: ein Regler pro Timer mit
  Symbol, ganz links *nie*. Neu: was das Zuklappen tut -- *Ruhezustand*, *Nur
  sperren* oder *Nichts*. Die letzten beiden verhindern den Ruhezustand,
  solange die Shell läuft.
- Das Musik-Widget ist das mit den Tasten: *Voll* und *Kompakt*. Seine
  *Welle* ist zum Visualizer gewandert, der denselben Klang zeichnete, und
  ersetzt dort die *Balken*. Ein Desktop mit einer der beiden bekommt die
  Welle am Visualizer.
- **Arbeitsflächen.** Fenster zählen ist jetzt ein Schalter für jeden Stil
  statt eines eigenen Stils: Einstellungen > Leiste > Anordnung > Arbeitsflächen
  > *Fenster zählen*, oder `qs -c ashen ipc call bar ticks`. Punkte lassen es
  weg, die Striche säßen auf dem Punkt.
- Spezielle Arbeitsflächen zeigen ihr eigenes Symbol (Musik, Discord, Notizen,
  Fav) in jedem Stil außer Kanji, sodass ein Punkt oder eine Zahl nicht mehr
  verbirgt, welche offen ist. In Pac-Man stehen sie ohne Block dahinter, und
  die offene wird zu Pac-Man.
- Im Symbolstil zeigt eine leere Arbeitsfläche einen leeren Ring statt ihrer
  Nummer.
- Das Bildschirmzeit-Widget sieht aus wie die anderen Widgets: das Symbol
  jeder App auf einer Plakette, ihre Zeit und ein Balken für ihren Anteil am
  Tag.
- Mehr von der Shell spricht deine Sprache: die Kürzelliste unter
  Einstellungen > Eingabe, die Namen der Pillen, die Widget-Leiste, die
  Widget-Formen, die Ordner der Auswahl und die Standard-Apps.

### Behoben
- Panels ohne Pille (Starter, Einstellungen, Zwischenablage, Energiemenü)
  öffnen jedes Mal gleich. Sie begannen ihre Animation, bevor ihr Fenster
  sichtbar war, und verloren je nach Lage ein anderes Stück davon.
- Panels ohne eigene Pille (Einstellungen, Starter, Zwischenablage,
  Energiemenü, Hintergründe) öffnen mit derselben Bewegung wie der Rest: eine
  pillengroße Kapsel erscheint an seinem Platz und dehnt sich zu ihm, dann
  der Inhalt auf einmal. Die
  Arbeitsflächen-Vorschau wächst wie die anderen Panels aus ihrem Chip, und
  ihre Fenster erscheinen mit dem Rest statt einzeln hereinzufallen. Sie
  beginnt genau auf dem Chip in seiner Farbe (Akzent beim aktiven), während
  der Chip wie jede Pille zurücktritt: vorher lag kurz ein dunkles Quadrat
  still darauf, und der Chip schaute an den Rändern hervor.
- **Panels ordnen ihre Teile unterwegs nicht mehr um.** Die Pille wird
  dunkel, die Box dehnt sich aus ihr, und der Inhalt blendet an seinem Platz
  ein; beim Schließen blendet er zuerst aus. Fliegende Teile brachen in der
  Vorschau und anderswo. Und der Teil eines Panels über der Leiste nimmt
  Klicks an: die Shell hält den Streifen für die Pillen frei, Tasten darin
  waren tot.
- Die Beschriftung der Arbeitsflächen-Vorschau ist, was der Chip zeigt --
  ein Kanji, Pac-Mans Geist, eine App -- nicht immer die Zahl.
- Panels aus einer Pille halten ihren Inhalt an der Leistenseite: zentriert
  rutschte er in der Box und war beim Schließen halbiert (Akku).
- Ein Panel lässt beim Öffnen nicht mehr zuerst seine Pille aufleuchten: die
  Akzentfüllung gehört zum Fensterstil. Die USB-Pille färbt nur ihr Symbol,
  wenn etwas eingehängt ist.
- WLAN, Bluetooth und die anderen Panels auf einer Platte beginnen an deren
  Kante. Benachrichtigungen und Prozesse wachsen aus ihren Pillen.
- Der Installer ersetzt ein qt6ct aus dem AUR (qt6ct-kde u. ä.) durch das
  aus den Repos. Es galt als installiert, passt aber nur zu dem Qt, gegen das
  es gebaut wurde: nach dem nächsten Qt-Update verwarf Qt es stillschweigend,
  und Starter und alle Qt-Apps verloren ihre Papirus-Symbole.
- Die Welle im Musikpanel lag auf dem Albumnamen; die Karte ist etwas höher.
- Das versteckte Dock verschwindet nicht mehr, sobald der Zeiger über die
  Symbole hinausschießt: Es wartet kurz, und wer zurückkommt, behält es. Der
  leere Streifen daneben schluckt keine Klicks mehr für die Fenster darunter.
  `qs -c ashen ipc call dock autohide` schaltet das Verstecken um.
- AM und PM sehen in jeder Sprache gleich aus: Spanisch schrieb "p. m.",
  zu breit für die Leiste und die Sonnenaufgangszeile.
- **Zwei Tastaturen, zwei Layouts.** Hyprland merkt sich ein Layout pro
  Tastatur, und eine, die später auftauchte (ein Funkempfänger, der aufwacht,
  ein USB-Stecker, die Anmeldung), begann auf dem ersten Layout, während der
  Rest auf deiner Wahl blieb. Jetzt folgen alle der Wahl, und eine späte wird
  binnen weniger Sekunden eingefangen.
- Der Installer scheiterte am Cursor: `bibata-cursor-theme` baut aus den
  Quellen und braucht ein weiteres AUR-Paket, also installiert er jetzt
  `bibata-cursor-theme-bin`. Seine Wiederholungszeile schickt dich für
  AUR-Pakete nicht mehr zu pacman.
- Desktop-Widgets hängen nicht mehr am Visualisierer-Schalter: ist er aus,
  werden Leiste, Musikpanel und Sperrbildschirm still, aber Visualisierer- und
  Musik-Widgets bewegen sich weiter -- cava hört zu, solange eines davon da ist.
- Die Musikwelle der Leiste war im Insel-Stil aus; jetzt erscheint sie dort,
  zwischen den Platten, wie zwischen den Pillen.
- Pac-Man gleitet von Arbeitsfläche zu Arbeitsfläche wie der Indikator der
  anderen Stile, statt von einem Chip zum nächsten zu springen.
- Ein Geist steht nur dort, wo wirklich Fenster sind: die gerade verlassene
  Arbeitsfläche zeigte kurz einen.
