# Änderungen

Übersetzung der Notizen aus CHANGELOG.md. Nur die aktuelle Version wird
gebraucht: fehlt sie, zeigt die Begrüßung die englischen Notizen.

## 3.3.1

### Neu
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
