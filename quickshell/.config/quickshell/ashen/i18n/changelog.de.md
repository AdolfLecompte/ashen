# Änderungen

Übersetzung der Notizen aus CHANGELOG.md. Nur die aktuelle Version wird
gebraucht: fehlt sie, zeigt die Begrüßung die englischen Notizen.

## 3.3.1

### Neu
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
