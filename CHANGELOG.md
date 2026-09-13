# Changelog

## 3.1.0

### Added
- **Game mode.** Flat compositor, quiet shell, by hand only: `SUPER + SHIFT + G`,
  a chip under the power profiles, a switch in Settings, or
  `qs ipc call game toggle`. It turns off animations, blur, shadows, rounding
  and gaps, stops the visualiser, takes the desktop widgets down, holds
  notifications and keeps the machine awake. What Hyprland had is read first and
  put back exactly -- never with `hyprctl reload`, which would re-apply
  monitors.lua and throw away your screen layout. Restart the shell mid-game and
  it still knows how to leave.
- **A wallpaper per screen.** With a second monitor plugged in, the picker grows
  a screen selector; the pick lands on that screen alone. Videos too, one
  mpvpaper per screen, paused while covered. The palette follows the primary
  screen, and each screen gets its own wallpaper back at login.
- **The picker searches.** Type to filter by file name; Escape clears the search
  before it closes the picker. The card you are choosing is now as wide as its
  picture, so the wallpaper is shown whole instead of through a portrait slot,
  and its name sits in the corner.
- **Keep Awake has a third answer.** Off, *still locks* -- the screen stays on
  and the machine stays up, but the session still locks -- and *nothing sleeps*.
- **A capsule for the machine.** CPU and memory in the bar, dragged in from
  Settings > Bar > Layout like any other pill.
- **The monitor board answers the keyboard.** Arrows move the focus, Enter places
  the selected screen, Shift carries it.
- **The phrase bank doubled.** Every moment has at least four lines now, most six
  or seven, written per language.
- **Recording has a shortcut.** `SUPER + SHIFT + R` starts and stops it, and
  `qs ipc call record toggle|start|stop|status` drives it from a script. With
  the recording capsule taken off the bar there used to be no way to record.
- **Readings are rows of ticks.** Memory, drives, temperatures and the
  battery light up to their level; CPU, GPU and traffic draw each recent sample
  as its own tick, so a card shows the last minute instead of one number. The
  liquid that used to fill those cards is gone.
- **A wallpaper follows its own look by default.** A new one keeps the look you
  are wearing and remembers it; one you tell not to follow wears a standard look
  -- your saved default, or the shell as it ships. The dock is part of the look.
- **The desktop clock picks its own format**: like the bar, 12h or 24h, with or
  without seconds.

### Changed
- **The shell idles at under half what it did.** cava kept sending sixty lines a
  second of silence, and the shell parsed every one before throwing it away:
  it now sleeps after two quiet seconds and wakes on the first note. Battery,
  charger, brightness, the lock LEDs, CPU and memory are read from the kernel
  in-process instead of through a shell every few seconds.
- **Settings are written once per change, not once per field**, so changing
  several at once can no longer lose one of them.
- **One switch decides whether anything moves.** Every animation in the shell
  goes through the same primitive, which is what lets game mode still them all.
- **Wallpaper thumbnails are sharper**, sized for the wide card that now shows
  them.
- **Fewer words everywhere.** Where a glyph already names something, the word
  beside it went: captions under icons, "CHARGING" over a bolt, "Paired" under
  paired devices, a device named twice. System notices have short, translated
  titles. Numbers and states you cannot guess stayed, and so did the card names
  in the process monitor.
- **A choice that can grow is a list.** Language, notification sound and the
  dynamic palette style are picked from a list rather than a row of buttons.
- **Every slider is 16 px thick**, the pill modes offer only what each pill
  actually draws, the workspace style lives with the other pill options, and
  bar styles run from least to most: Pills, Island, Solid, Framed.
- **The picture picker is fast.** Thumbnails are cached and made in parallel,
  so a folder opened before shows at once.
- **Panels without a capsule come from the top** when the bar is at the bottom,
  instead of sliding in from the side.

### Fixed
- **An unplugged monitor stayed in the display board.** Hyprland keeps a pulled
  cable in its full list; the board now shows a screen only while it is lit, or
  while Ashen is the one keeping it off.
- **The blue-light filter did not come back after a restart**, and a stray
  wlsunset from an earlier session could fight the new one.
- **A pill reserved room for a label it did not have.** A disconnected Bluetooth
  chip kept 46 px of nothing.
- **The picker's toolbar was hard to see**: three thin plates over a photograph.
  It is one bar now, and the search icon no longer goes dark as you type.
- **A fresh machine without the AUR prompt theme got an error instead of a
  shell.**
- **A recording started with the capsule off the bar made the bar jump.** The
  capsule appeared at full size and its neighbours snapped aside on a frame of
  half-built pills. It now grows into place while they slide, and folds away
  before the gap closes.
- **On a side bar, desktop widgets sat under the pills**, and in dots the
  current workspace lay across the column. Widgets now keep clear of the bar,
  and the dot stretches along it.
- **Changing wallpaper kept the old bar length.** The length, outline, workspace
  style and pill modes are part of what a wallpaper remembers.
- **The picture picker slid twice** on every folder change; once now, and
  downwards.
- **Hovering the profile picture or the repo link cut them off** at the edge of
  their section. Wide things no longer grow under the pointer.
- **Settings rows had their buttons out of line** and some cards left dead
  space between sections.
- **The shell could crash on something you copied.** Text from outside -- the
  clipboard, notifications, track titles -- was left for Qt to guess whether it
  was HTML, and a copied `<img>` tag brought the whole shell down. Everything is
  plain text now, and notifications have their markup stripped.
- **A side bar went blank after being moved a few times**, leaving a wide empty
  plate where the capsules should be.
- **The machine widget still drew curves** for CPU and GPU; it draws ticks, and
  the option for the old look is gone.

## 3.0.0

### Added
- **One line installs it.** `install/boot.sh` is the only thing that travels
  over curl: it checks this is Arch, fetches the repo into `~/ashen` and hands
  over to `install/run.sh`, which draws a TUI and installs **each package as its
  own transaction** -- one bad target used to abort the whole thing, which is
  why fresh machines came up with no Nerd Font and half the packages missing.
  It reports what it installed, what was already there and what failed, and
  `--dry-run` touches nothing at all. The directory is no longer yours to get
  wrong: the installer picks it, so `~/Ashen` and `~/ashen` can no longer
  disagree about where the scripts live.
- **The installer draws itself.** Five steps on screen at once -- packages,
  dotfiles, login screen, services, folders -- each rewritten in place as it
  goes, with a bar and the package being installed. It used to print one line
  per package: 64 of them, scrolling past faster than they could be read, with
  no way to tell what was left. A failure is printed above the surface so it
  survives the redraw. On a pipe or in a dry run it prints plain lines instead,
  because cursor movement into a log is noise.
- **A login screen that is the shell.** An SDDM theme drawn with Ashen's own
  bar -- session, clock and the four ways out as real pills at the numbers
  `services/Sizes.qml` uses -- the ASCII mark on its plate, and the workspace
  dot strip counting your keystrokes instead of asterisks. Installed by the
  installer, which also repoints `/etc/sddm.conf`: on SDDM the plain file
  outranks a drop-in, so a theme installed only through `sddm.conf.d` never
  appears.
- **A dock.** Pinned and open applications along an edge you choose, revealing
  the way the utility pill used to. A click launches, focuses, or hides to a
  special workspace, in that order. It can be turned off, outlined, resized and
  moved to any edge.
- **The system plate came apart.** Network, bluetooth, sound, battery and
  keyboard are five separate pills now, each one arrangeable anywhere on the
  bar rather than riding together on one tray.
- **Every pill says how much it says.** `full`, `compact` and `icon` per pill,
  plus an outline style -- two axes, because a pill can be compact AND outlined.
  A pill that has nothing to trim is not offered the choice.
- **Workspace dots**, a third style beside icons and numbers, and a count: how
  many workspaces the bar shows is yours to set.
- **About knows what it is.** The version, a door to what changed in it, and an
  update check against the repository's releases -- which understands that a
  checkout can be AHEAD of the newest tag, and does not offer that as an update.
- **A welcome worth reading.** One card, two faces: the mark, then the keys that
  matter, in a grid.
- **The shell speaks four languages.** English, Spanish, Russian and German,
  picked in Settings > System and applied on the spot -- nothing restarts, and
  no language is compiled in: each one is a JSON file next to the shell, so
  adding a fifth is writing a file. Everything a person reads goes through it:
  the seven Settings tabs, the welcome and what's-new screens, every panel, the
  bar, the desktop widgets and the lock screen. A string a translation has not
  answered falls back to English by KEY, not by file, so a half-finished
  language is still usable.
- **Its own voice, written four times over rather than translated.** The bank
  of remarks -- what the lock screen says while it checks, what an empty panel
  says instead of nothing, what About says about updates -- is written in each
  language's own dry register: a line carried across word for word stops being
  one.
- **Dates and times follow the language too**, and never the system's: the
  shell says one thing in one voice. Day and month names, the calendar's
  weekday row, "Today" over the forecast, and the am/pm the weather prints.
- **An island bar.** A fourth style beside pills, solid and framed: instead of
  one plate from edge to edge, each section of the bar gets its own, and what
  is between them is wallpaper you can click through to.
- **The bar need not span its edge.** A slider in Settings > Bar takes it from
  100 % of its side down to 50 %, pulling both ends in and keeping its middle,
  so the corners go back to the windows -- the input region follows, so they
  really do. The framed style ignores it: there the bar IS the border.
- **The dock is edited from Settings too.** Desktop > Dock lists what is
  pinned, in order, with a search that pins anything installed -- the half of
  pinning that right-clicking the dock cannot do, because an application that is
  not running is not there to click.
- **From a keybind**: `ipc call language set|get|list`, `ipc call bar style`,
  `ipc call bar length`, `ipc call dock toggle|edge|pin|unpin|list`.

### Changed
- **The system pills carry the wallpaper.** Their glyphs rest on the scheme's
  tone the way the clock's weather icon always has, and "on" rests one step
  below snow so that hover has somewhere to go.
- **Hover in Settings moves the word, not the box.** A button that swells
  inside a card full of rows shoves the rhythm of the rows around; the bar's
  pills grow because they float on a wallpaper with nothing to disturb.
- **Settings was audited and rebuilt around what you are looking at**: the panel
  is a reading measure rather than 1460 px of dead space, each pill's controls
  live in the pill's own card instead of at the far end of a row, and About
  leads with the mark rather than the word.
- **"Glass" is called "Outline"**, which is what it draws -- and it is now ONE
  switch for the whole bar rather than one per capsule. Fifteen of them was
  fifteen ways to end up with a bar that is half glass and half plate.
- **The outline belongs to the plate of the style in use.** In `solid` the whole
  bar becomes a frame, in `island` each island does, in `framed` the ring is
  drawn instead of filled; only in `pills` does a capsule outline itself. A
  drawn edge with a solid middle is not an outline, it is a button.
- **A capsule only fills itself when it IS a capsule on a wallpaper.** On a
  solid or island bar, or in outline, "on" is carried by the letters taking the
  accent -- a filled block inside a filled plate is a block inside a block. The
  reading rests brighter there too, or wifi and bluetooth read as switched off
  beside a battery that did not.
- **Settings was reorganised around what each word promises.** The bar moved out
  of Desktop into its own tab -- it was carrying the bar, the dock AND the
  wallpaper widgets under one name that answered for none of them -- Devices is
  called Sound, which is all it held, and the default applications moved to
  System, because which terminal opens is not something you type.
- **The profile picture moved** out of About and next to the lock screen it
  appears on.
- **The utility pill is gone.** Its three tools keep their keybinds, and the
  dock inherited the edge it used to peek from.
- **A widget's name yields to its figure** rather than running under it, and a
  weather cell's caption elides inside its quarter of the row. Both were drawn
  around English words and translations are longer.
- **A network you join from the scan flies into the middle.** Agreeing to a
  stranger sent the SCAN CHIP riding back to its slot, so the one piece that
  moved was the one you had not picked -- the network you chose simply appeared
  in the centre a second later. It travels there from the slot you picked it in
  now, the same journey a saved node makes, and the ring only goes back to the
  saved networks once it has landed.
- **A saved network can be forgotten from the graph.** Right-click the node and
  it asks; right-click again and it goes. It used to be Settings or nowhere,
  because the panel lost its "connected" card and the forget button with it. It
  asks rather than acts, since a stray click on a saved network is not something
  to be sorry about afterwards, and the question is drawn in the accent -- this
  shell does not say destructive in red.
- **The picture chooser says what it is choosing.** The same box answers two
  different questions -- the lock screen's face and a wallpaper widget's picture
  -- and it opened on a path and nothing else, so the only way to know which one
  had asked was to remember asking. It dims the desktop behind it now instead of
  floating over a lit window, its thumbnails fade in as they decode rather than
  filling a field of empty plates at random, the tiles share out the row instead
  of leaving a column of dead air at the right edge, a rule separates the places
  from the grid, and a folder still being read says so -- an empty grid and a
  folder with no pictures in it used to look exactly alike. Changing folder
  sweeps the way you walked -- out towards where you came from, in from where
  you went -- instead of nudging down and back on the same side, which says a
  list reloaded rather than that you moved. And hovering a tile grows it INTO
  its slot: it used to scale past it, overlapping its neighbours and being cut
  off by the grid's own clipping on the rows at the top and bottom of the view.
- **One package fewer.** `zenity` was still a hard dependency of a shell that
  stopped using it: choosing a picture and choosing a folder are both the
  shell's own dialogs now, and the only zenity left in the tree is a window rule
  naming its class. `xdg-utils` was listed twice over, as a dependency and as an
  optional one.

### Fixed
- **Two packages did not exist on Arch, and two were listed as if they did not.**
  `mpvpaper` and `zsh-theme-powerlevel10k` were in the official list and are not
  in the official repos -- this machine only had them because CachyOS ships them
  in its own -- while `awww` and `matugen` were listed as AUR after landing in
  `extra`. Found by installing into a clean Arch container, which is the only
  place where "it works here" stops being an argument.
- **Shortcuts could not be rebound at all.** Hyprland runs its own binds before
  the key reaches the client, so a chip waiting for SUPER+T opened a terminal
  and never heard the press. While Settings listens, the session now sits in an
  empty submap where every key falls through.
- **A toast could arrive with its title and nothing under it.** The phrase bank
  is read asynchronously and Keep Awake fired while restoring preferences, when
  the bank was still empty. The remark is a binding now: a binding re-runs when
  the bank lands, a signal handler never does.
- **Three Settings tabs could not be scrolled**, so anything past the fold was
  simply unreachable.
- **The dock did nothing at all when you clicked a running application.** It
  spoke to Hyprland in the classic dispatch syntax (`focuswindow class:^(x)$`),
  which a Lua config answers with a parse error and no window ever moved. The
  same mistake was in the generated `hypridle.conf`, where it meant **the screen
  never went dark on idle**, and in the shortcut editor.
- **The screen selection was drawn invisible.** The screenshot keybind asked
  slurp for a zero-width border on a transparent screen, so you dragged an
  unlit rectangle over an undimmed desktop. It now dims the screen and draws its
  edge in the shell's accent -- and the black line that used to appear along a
  capture is gone with it: grimblast disables the selection's animation itself,
  but it does so through `hyprctl keyword`, which a Lua config refuses, so the
  rule now lives in `windowrules.lua` where it holds.
- **The screenshot toast never said where the file went**, which is the one
  thing anybody wants to know afterwards. It names the folder now.
- **The recording timer disappeared while recording** on any bar style whose
  capsules do not fill: it was painted in the colour meant to be read ON the
  accent, with no accent behind it.
- **Workspace icons could not be turned off** -- the preference existed and was
  honoured, but nothing in Settings offered it.
- **`conf/appkeys.lua` bound the four app keys to `undefined`.** Nothing ever
  required the file; it only shipped and confused.
- **Sunrise and sunset were read out of the printed time.** The clock panel and
  the sun widget both parsed "6:12 PM" back into a number, which is fine until
  the printed time changes with the language. Weather now publishes the two as
  minutes past midnight, and nothing parses a string that is drawn on screen.
- **Every system capsule sat lit in the accent all day** on a solid, framed or
  outlined bar. Where a capsule cannot fill, "on" is carried by the letters --
  and the wifi, the bluetooth and the sound reading are *on* whenever their
  radio is, which is nearly always. Only an open panel accents them now; what
  the radio is doing is the glyph's job, which is what the battery beside them
  was already doing. The keyboard layout stops shouting too: it rested a step
  brighter than everything else for no reason of its own.
- **The media capsule came back empty** after the bar was moved to a side edge
  and back: a plate of the right width with no cover, no title and no transport
  inside it. Its row swapped four anchors at once to change axis, the four do
  not re-evaluate in a fixed order, and for one frame two of them contradicted
  each other -- Qt drops one of a conflicting pair, and what was left was the
  position the other edge had used, which the plate then clipped away. It is
  centred on both axes now and swaps nothing.
- **A side bar had three different gaps in it.** Two buttons stood 4 px apart,
  a button and a tall capsule 12, two tall capsules 20 -- because a tall one
  bought air on each of its sides and two of them in a row paid for it twice.
  One gap now, the same between any two neighbours: a 44 px button already
  reads as a different thing from a 190 px column without the space saying so.
- **The layout editor's plates could not grow past three rows.** They were
  written when there were eleven capsules to arrange; the day the system plate
  became five separate pills a section could hold more than fits, and the chips
  wrapped out through the bottom of a plate that has no clipping on purpose.
  Three rows is the floor now, and the three bar sections still draw as one
  height so the row keeps reading as three equal places.
- **The dock lost its plate whenever the bar was solid or framed**, leaving bare
  icons floating over the wallpaper. It was painted with the token that means
  "the bar is one plate, so its capsules do not paint a second one" -- a
  sentence about the bar, borrowed by a surface on another edge entirely.
- **The dock's position picker offered three sides and no explanation.** The
  missing one is whichever edge the bar is on, so the answer moved with the bar
  and looked like a feature that was not finished. All four are shown now, the
  bar's own greyed out with a line saying why. The dock also steps to the
  opposite edge by itself if the bar is later moved on top of it -- the picker
  could refuse the choice, but nothing stopped you making it the other way
  round.
- **The three power profiles were an unlabelled leaf, balance and rocket.** The
  battery panel's own comment says the word is what ends the guessing, and the
  word had gone missing: the model rows carried an id and a glyph and no label
  at all, so the shell printed "Unable to assign [undefined] to QString" three
  times on every single start and drew three anonymous icons. They say Saver,
  Balanced and Performance again, in whatever language you are running.
- **Half the surfaces never drew the panel outline.** Everything that reads the
  panel colour got thinner when the outline was switched on, but only three
  places drew the line itself -- the notifications, the tray menu, the OSD, the
  media and clock cards and the wallpaper's own editing surfaces went
  see-through and stayed edgeless. The width is one token now, next to the fill
  it belongs with, rather than a preference each surface had to remember to
  spell out.

## 2.2.0

### Added
- **A welcome screen, and a what's-new screen.** The first time the shell ever
  runs it says what it is and the four keys that make it usable; after an
  update it shows what changed, read straight out of this file rather than
  written twice. `ashen-welcome` brings either one back.
- **Settings is seven tabs instead of ten**, grouped by what you are trying to
  change: Look, Bar & Desktop, Panels, Screen, Devices, System, About. The
  weather no longer lives inside "Bar", the wallpaper sits with the palette it
  generates, and Wi-Fi and Bluetooth stopped being a switch inside a switch.
  Every old tab id still resolves, so keybinds and `ipc call settings tab …`
  keep working.
- **The Wi-Fi and Bluetooth rings page.** When more networks are in range than
  the ring can hold, one slot becomes `+N`: pressing it folds the ring into the
  hub and throws it back out with the next page, so a crowded café no longer
  means opening Settings.
- **The words stand beside the music.** The media panel's lyric drawer is gone;
  the lyrics are a column of the card itself, next to the cava, and the card
  measures itself so the panel grows with them. A track without words takes the
  column's width back. The chip on the card (or Settings) hides them, and it
  remembers.
- **`ashen-widgets`** — the desktop widgets from a terminal: the editor, the
  tray, what is out there and where, shapes, skins, snapping, copies.
- **The lock screen keeps its music and its notices** even with nothing playing
  and nothing waiting. Both cards already had a voice for silence; a column that
  loses a card between one unlock and the next reads as something missing.
- **The battery's last 24 hours draw themselves in** when the panel opens,
  oldest hour first.
- **The picture on the desktop is handled from outside itself.** The corners you
  pull now float just off the frame instead of sitting on top of the picture,
  and framing — sliding and zooming the picture inside its frame — is a button
  beside them rather than a control laid over the thing it frames. Both belong
  to the arrangement, not to the widget, so any widget can ask for them.

### Changed
- **Panels open in four beats instead of all at once.** The capsule's lit fill
  drains and what it says goes quiet; still pill-shaped, it leaves the bar and
  travels to where the panel lives; only once it has arrived does it become the
  card, its contents sliding out as the box opens; and what it carried lights up
  last, in place. Closing runs the beats backwards — the card becomes a pill
  again, goes home, and only there takes its colour back. Every capsule on the
  bar now opens the way the clock and the media panel always did, and no box
  bounces on arrival any more.
- **A card only travels between sizes in the transform style.** Choosing
  "window" asked for a panel that does not transform, and a card that resized
  itself as you walked between sections was doing exactly that.
- **Less text.** The battery panel stopped saying its own captions again in
  words, and stopped announcing "Fully charged" under "CHARGING". In Settings,
  seven paragraphs that explained what the control next to them already says are
  gone or down to a line.
- **The image picker's places carry one travelling accent** rather than each row
  lighting its own plate the instant you press it.
- **Cava is drawn in the accent**, in the panel and on the desktop both. Mixed
  into the plate it read as a picture of a visualiser; silence is said by the
  bars collapsing onto their axis, not by the colour fading.
- **The progress line breathes with the song**: its height follows the live
  level, what is still to come is a straight dim rule, and the playhead is a dot.

### Fixed
- **A desktop widget could not be resized.** The area that drags a widget around
  is declared after its contents, so while arranging it swallowed every press
  meant for something inside — including the corners that size a picture.
- **The piece carried out of a chip stayed in the bar** while the card travelled
  away from it, then fell on its own afterwards: it was pinned to the chip's
  place on screen rather than riding the card. It also arrived already lit, and
  was drawn with a colour that resolved to nothing (a warning on every open).
- **The installer was missing six packages** that features added since July need:
  cover art and lyrics (`curl`), wallpaper thumbnails (`imagemagick`), the
  pending-updates readout (`pacman-contrib`), the wallpaper script's monitor
  lookup (`python`), opening the app behind a notification (`gtk3`), and the
  palette Qt apps read (`qt6ct`). It also caches the wallpaper thumbnails on
  install now: the picker used to open on blank cards, and a video has no
  fallback to show meanwhile.
- **Nothing on the desktop could be clicked.** The wallpaper layer took no input
  at all unless you were arranging, so the music widget's transport was a row of
  buttons that did nothing. The layer now cuts a hole for the widgets that have
  something to press, and only those.
- **The workspace preview obeys the panel style.** It rolled its own morph, so
  it ignored the transform/window setting entirely and kept a bounce the rest of
  the shell had given up. It arrives like every other panel now, and the windows
  inside it drop in one at a time.
- **Panels that outlived what they were about.** Pulling the last USB stick left
  its card hanging off a pill that no longer existed, and so did the media panel
  when the music stopped. Both close themselves now.
- **The profile picture card was clipped on hover.** It grew by 6% — thirty-odd
  pixels on a card that wide — instead of the four the shell gives a big surface.
- **A group of notifications unrolls instead of appearing.** The rows came out
  of a Repeater, which has no transitions, so opening a run built them in one
  frame and closing destroyed them in another.
- **Every remark in the shell was a binding loop.** `Voice.pick()` reassigned its
  own "last line" map, and half the shell picks its line in a property
  initialiser — so each pick re-ran all of them. The map is written in place now.
- **The media pill was 14 px wider on one side than the other.** A `Grid` with
  more columns than items still charges one `spacing` for the empty one, and it
  landed past the last chip. Both grids count their cells.

## 2.1.1

### Changed
- **Accent folders are no longer a setting** — they are how Ashen looks, so the
  switch in Appearance is gone and `ashen-folders.sh` applies by default
  (`--off` still walks it back).
- **The system board wears the scheme's own colours** — the tones were the
  accent spun round the hue wheel, which produced colours the wallpaper never
  made. They come from the palette now, one to a card, and Thermals no longer
  turns red past 80°: a warm CPU is the panel doing its job.

### Fixed
- **The power menu arrives without a card around it.** A `DropCard` always
  landed on the panel surface, so the four tiles turned up inside a box when
  opened from the pill in transform style — and a plate that is only there
  while it travels is still a box you watch arrive. A plateless panel paints
  none at any point.
- **Fixed colour schemes repaint the folders.** They read the accent from
  `~/.cache/ashen_accent.txt`, which only the dynamic road ever wrote, so the
  folders kept whichever wallpaper wrote it last. A fixed scheme publishes its
  own accent now — which fixes the window border the same way.
- **The bar editor's drop preview stays inside its plate**, anchored to the gap
  instead of straddling it, and the chips step aside to open real room for it.

## 2.1.0

### Added
- **Caps Lock and Num Lock are back on the bar**, as two chips to the left of
  the keyboard layout — in the slot the brightness chip left free. They are not
  lit and unlit: a lock that is off is not a state worth a slot. They arrive in
  two beats — the slot opens, then the chip appears — and leave in the other
  order, so the strip is never seen shoving its neighbours aside.

### Changed
- **The lock state belongs to the keyboard now** — it was polled inside the
  notification service, with a second `hyprctl` of its own. `services/Keyboard.qml`
  reads it off the same call the layout already comes from, and the bar and the
  toasts share that one answer.

## 2.0.2

### Changed
- **The battery dial is a ring again** — the liquid inside it said what the rim
  already said, and left the reading sitting in a puddle.
- **Sliders lost their knob** — sound and every slider in Settings are just the
  bar now: the filled part already says where the value is. The grab area is
  unchanged, it never came from the dot.
- **The brightness panel is gone**, and so is its capsule in the bar — a whole
  card, and a chip of its own, for one number the keys already change. The
  slider moved to the foot of the sound panel, which is the panel you open to
  change a level anyway; Settings → Display still has its own.
- **The OSD fills with a vertical gradient**, down the bar rather than across
  it, and keeps up with a key held down: a reading asked for while the previous
  one was still in flight used to be dropped, and the fill animated over 260 ms
  when the next press was 80 ms away.

### Fixed
- **Updating from an older version actually updates.** `stow` ran all nine
  packages as one transaction, so a single link it did not consider its own —
  one made by hand, or with an absolute path — aborted the lot and the update
  changed nothing but a warning. Links that already point into the repo are
  dropped first and each package is stowed on its own.
- **The GTK palette is regenerated on every setup**, not only when it is
  missing: an update brings new templates, and a machine that already had a
  `gtk.css` kept the one the old templates wrote.
- **`papirus-folders` is no longer called by the installer** — it re-runs itself
  under sudo, which a hardened sudoers refuses, and it only knows the colours
  Papirus ships. The accent folder theme is built instead.

## 2.0.1

### Added
- **Accent folders** — `scripts/ashen-folders.sh` builds an icon theme that
  inherits Papirus and repaints only the folders with the accent of the moment,
  rebuilt whenever the wallpaper moves it. Switched on in Appearance → Folders.
  The four tones are chosen by the accent's luminance, so a light-mode accent
  (which is a dark colour) gets a light emblem instead of Papirus' dark one.

### Fixed
- **GTK apps dissolving into the wallpaper** — Hyprland already draws every
  window at `active_opacity 0.70` with blur behind it, and the generated CSS
  added a second `alpha()` on top. Over a light wallpaper that left the file
  names in Nemo and the portal's file chooser sitting on the picture with
  nothing behind them. The backgrounds are solid now, and the file managers and
  the portal dialog keep a near-opaque window rule of their own.
- **Light mode never reached the apps** — the GTK theme name and the
  colour-scheme preference were written once at install time and pinned to
  dark, so switching Ashen to light left our colours light and `adw-gtk3-dark`
  serving its own dark tones for everything else. `scripts/ashen-gtk-mode.sh`
  now owns both (and Nemo's Cinnamon namespace, which reads its own), and runs
  on every switch.
- **The fixed schemes wrote a different CSS** — the non-dynamic path painted
  windows nearly transparent, wrote only GTK3, and never restarted the portal.
  It now matches the matugen templates, writes GTK4 as well, and hands over to
  the mode script.
- **libadwaita fell back to dark** — every colour name GTK4 could not find used
  its dark default; the missing dozen (`dialog_*`, `shade_color`,
  `sidebar_backdrop_*`, `thumbnail_*`, …) are defined.
- **`xdg-desktop-portal-gtk` was never declared** in the installer or the
  package, though it serves the settings portal to GTK apps and Ashen already
  restarted it.
- **`wlsunset` missing from the package** — the night light had a switch that
  did nothing on a package install.

## 2.0.0

The shell was taken apart and put back together. Everything that used to be a
row of controls is now a panel that arrives, and everything that used to be a
number is now something you can read at a glance. Sixty-odd commits; the parts
that change how Ashen is used:

### Added
- **Multiple monitors** — a 3×3 board arranges the screens, workspaces belong to
  a monitor, and the bar, the panels and the lock screen all appear on every
  screen instead of only the primary one.
- **Panels instead of rows** — every readout opens as a panel that either grows
  out of its own capsule or unfolds where it lives (`Appearance → Panel style`
  picks which). Sound, brightness, battery, network, bluetooth, clock, power and
  the process board were all rebuilt on it.
- **Light mode** — seven light schemes, and text colour chosen by the luminance
  of whatever it sits on rather than by the name of the token.
- **Settings, in tabs** — nine sections with a rail, including a bar layout
  editor, per-app volume, night light (`wlsunset`) and a display arranger.
- **Liquid gauges** — sound, brightness, battery and the system board read as
  vessels filling up, with the swell following the reading.
- **Notifications with a history** — grouped by app, unread marks, working
  D-Bus actions, and a sound of its own.
- **Lock screen in two faces** — at rest it shows the clock, the weather, the
  battery and what is playing; touched, it asks for a password.
- **A package** — Ashen installs as a package (shell to `/etc/xdg/quickshell`)
  instead of only as a checkout.

### Changed
- **One accent, decided once** — `scripts/ashen-accent.sh` picks it by WCAG
  contrast and every consumer (shell, kitty, p10k, btop, Qt, cava, GTK) reads
  that one answer, so nothing disagrees after a wallpaper change.
- **One animation table** — every duration and curve comes from `Sizes`; the
  overshoot is capped and hover is always "grow and brighten", never a fill.
- **The clipboard** — text entries are a grid like the captures, and the
  categories moved to the top of the panel.
- **The utility pill** — a fixed set of tools on every free screen edge.
- The emoji picker, the glyph picker, the quick notes and the caps/num pill were
  retired; the design rules that replaced them are written down in
  `docs/DESIGN.md`.

### Fixed
- **Drop-down lists that could not be clicked** — a floating list drawn outside
  its ancestors is painted but never receives mouse events. The device picker
  now hands its list to the window instead.
- **Toast sweep** — dismissing them all no longer plays half an animation on
  cards that were never on screen, and a card rebuilt mid-exit resumes instead
  of jumping to its last frame.
- **Deleting notifications** — rows commit in their own batch, so a second
  delete no longer postpones the first, and a group's title leaves with its last
  row instead of hanging over nothing.
- **Installer** — `wlsunset` was missing, so the night light silently did
  nothing on a fresh install.

## 1.5.2

### Fixed
- **Installer resilience** — package install no longer aborts wholesale when a
  single package conflicts. `pacman -S` runs everything in one atomic
  transaction, so one bad target (a renamed package, an AUR `-git` variant, or
  a base package like PipeWire that CachyOS ships as a newer `-1.1` rebuild the
  plain repo would "downgrade") used to block every other package. Now the
  batch is tried first and, on failure, each package is installed individually
  so the good ones still land and only the genuine conflicts are skipped and
  reported.

## 1.5.1

### Fixed
- **Portability** — every path now resolves from `$HOME` at runtime instead of
  the hardcoded `/home/adolf`, and the install-time `sed` that rewrote the
  working tree is gone. `git pull` no longer dirties the tree or conflicts on
  each release, and paths that pointed at the repo checkout (glyph data,
  `general.lua`, `input.lua`) now use the stowed `~/.config` location, so they
  hold wherever the repo was cloned.

## 1.5.0

### Added
- **Audio device picker** — choose the output (speakers / headphones / HDMI)
  and input (microphone) from the volume panel and **Settings → System**, like
  Noctalia. Switching moves already-running streams, so it takes effect at once.
- **Cycle workspaces** with `SUPER + CTRL + ←/→` (next / previous, same
  monitor).
- Installer now adds the user to the `video` group so the webcam works out of
  the box.

### Changed
- The Bluetooth panel device list caps at 5 rows and scrolls past that instead
  of overflowing.

### Fixed
- Discord notifications now show the Discord icon instead of a generic Material
  glyph (icons resolve by app name when no `appIcon` is sent).
