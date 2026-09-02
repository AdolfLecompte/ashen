# Ashen — design rules

The shell looks like a collage because every panel was designed on its own and
nothing was ever written down. This file is the missing agreement. It is not a
redesign: the panels that exist now are the reference, and these rules are drawn
from what they already do well. Anything that disagrees with the rules is what
gets corrected.

**Read this before adding a panel, a button, or an icon.**

---

## 0. What is actually wrong today

**Settings was brought onto these ladders on 2026-08-07** — every tab and every
`settings/components/*`. What that pass found and fixed, because the same things
will be true of anywhere else that has not had it yet:

- **No text size is written as a number any more**, only `Sizes.fs*`. The tabs
  were using 27 distinct sizes between them, and 12/15/16/22/26 were not on the
  ladder at all. Glyph sizes were left alone: they ride with their text.
- **No raw alpha survives** — 17 different `ghostAlpha()` values collapsed onto
  the five `Colors.fill*` roles. Two scheme tiles were lighting up on hover at
  0.30 against an active state of 0.28, so the two states looked identical;
  those now use the hover rule (grow and brighten) like everything else.
- **No raw radius survives** — 9 values onto the five shape steps.
- **Dividers are gone.** A panel says where one thing ends by starting the next
  one, in a box. Four `Divider {}` remained across the tabs; two were inside a
  single card separating rows that belonged together, two became card boundaries.
- **A control at the end of a row needs an explicit `Item { Layout.fillWidth }`
  spacer.** 17 toggles and steppers across seven tabs were hugging their label
  instead of sitting at the card's right edge, which is most of why the panel
  read as loose. `Layout.fillWidth` on the label column alone does not do it.

The list tabs — Network, Wi-Fi, Bluetooth — deliberately keep their lists rather
than being poured into cards: a list of networks is not a stack of settings rows.
They share the ladders with everything else, which is what they were missing.

Measured across the 21k lines of QML in `quickshell/.config/quickshell/ashen`:

| Thing | Distinct values in use | Should be |
|---|---|---|
| `font.pixelSize` | **27** (8→104) | 9 steps |
| `radius` | **22** (1→64) | 5 steps |
| Animation `duration` | **42** | 5 steps |
| `easing.type` | 10 curves | 3 curves |
| `ghostAlpha()` | **24** opacities | 5 roles |
| `surfaceAlpha()` | **9** opacities | 2 roles |
| Small icon-button | **6** implementations | 1 component |
| Glyph for "delete one thing" | **3** (`e5cd` ✕, `e872` 🗑, `e92e` 🗑) | 1 |

Six icon buttons, side by side, all meaning "small square you click":

| Where | Side | Radius | Idle | Hover | Glyph | Hover motion |
|---|---|---|---|---|---|---|
| `IconBtn` — NotificationPanel | 30 | 8 | transparent | ghost .15 | 16 | scale, 150 ms |
| `CloseBtn` — NotificationToast | 22 | 7 | transparent | ghost .30 | 12 | scale, 150 ms |
| `StepBtn` — Settings | 28 | 8 | ghost .12 | ghost .25 | 18 | none, 120 ms |
| `DeleteBtn` — Clipboard | 26 | 8 | transparent | ghost .28 | 14 | scale, 150 ms |
| `CtlChip` — widgets | 32 | 8 | ghost .20 | ghost solid | 18 | scale, 140 ms |
| kill button — ProcessPanel | 24 | 8 | transparent | ghost .30 | 14 | scale, 150 ms |

None of these differences mean anything. They are all accidents.

---

## 1. Principles

1. **One idea, one icon.** A meaning gets exactly one glyph across the whole
   shell. If two places do the same thing they look the same; if they look
   different they must *be* different.
2. **Pick from the ladder.** Sizes, radii, opacities and durations come from the
   scales below. A number that is not on a scale needs a comment saying why.
3. **Don't roll your own control.** If a component exists, use it. If it almost
   fits, extend it — a sixth private copy is never the answer.
4. **Everything comes from somewhere.** A panel grows out of the thing that
   opened it. Nothing fades in at the centre of the screen.
5. **No bounce on arrival.** A panel that overshoots reads as a toy. See §6.
6. **Destructive is not loud.** Delete, forget, clear and kill use the scheme's
   own colours, never red. Red (`error_`) means *something is wrong*, not
   *this button removes things*.

---

## 2. Type scale

Nine steps. Font is `JetBrainsMono NF` for all text, `Material Symbols Rounded`
for all glyphs — **never mixed in one `Text`** (the digits render as tofu).

| Token | px | Bold | Use |
|---|---|---|---|
| `caption` | 9 | no | The line under a title; units; footnotes |
| `meta` | 10 | no | Column headers, labels beside a value |
| `body` | 11 | no | List rows, entries — the default |
| `bodyLg` | 13 | no | Search fields and anything typed into |
| `cardTitle` | 14 | **yes** | The name of a card inside a panel |
| `sectionTitle` | 17 | **yes** | A panel column's heading (`SectionHead`) |
| `panelTitle` | 20 | **yes** | The panel's own name, when it has one |
| `readout` | 24 | **yes** | A number that is the point of the card |
| `hero` | 42 | no | Empty-state glyph, lock clock |

Glyph sizes ride with their text: 16 next to `body`, 17–18 next to `cardTitle`,
21 in a `SectionHead` box.

**Rule:** a panel uses at most four steps. If it needs five, it is two panels.

---

## 3. Shape

| Token | px | Use |
|---|---|---|
| `innerR` | 8 | Chips, icon buttons, small plates |
| `pillR` | 10 | Bar pills, input fields |
| `cardR` | 14 | A card inside a panel |
| `cardLgR` | 18 | A hero card (the CPU block) |
| `panelR` | 22 | The panel itself |

Spacing is `4 · 6 · 8 · 10 · 12 · 14 · 16 · 18`. Panel margin is **18**, gap
between cards **12**, gap inside a card **6–10**.

### Only two shapes exist

**Every box in the shell is a rounded rectangle or a circle. There is no third
kind.** No sharp-cornered panels, no cut or bevelled corners, no chamfers, no
angled edges, no tabs with pointers, no speech-bubble tails. A square is a
rounded rectangle whose sides happen to match; a pill is one whose radius
happens to be large. Those are variations, not exceptions.

Circles are for readings that go round — dials, rings, avatars. Everything that
holds content is a rounded rectangle.

Three things are **not** boxes and the rule does not reach them:

- **Connectors** — the goo neck that ties a drop to its bar while it pinches off.
- **Plots and gauges** — sparklines, dials, the Cava bars, the node-graph wires.
- **Invisible or full-bleed layers** — click-off catchers, dim scrims, the lock
  screen's gradient wash, a 2 px text caret. These have no corners to round:
  they either cover the whole screen or are a line.

One apparent exception that is not one: a shape **glued to a screen edge** keeps
that edge's two corners square. It is still a rounded rectangle — the corners
that were squared are outside the screen. Rounding them carves a notch, because
there is nothing behind the curve to blend into.

---

## 4. Colour roles

The palette is `services/Colors.qml`; matugen rewrites it per wallpaper, so
never hardcode a hex. What each name is *for*:

| Role | Token | Meaning |
|---|---|---|
| Primary text | `snow` | The thing you are reading |
| Secondary text | `mist` | Labels, units, the second line |
| Tertiary text | `ash` | Detail you only read if you look for it |
| Accent | `ghost` | This is on / active / selected |
| Accent, darker | `shade` | Only inside `accentGradient` |
| Alarm | `error_` | Something is **wrong** — never "this deletes" |

Text on an accent fill is always `Colors.onColor(bg)`, never a fixed dark.

### What goes ON a surface — four tokens, not sixty-seven `onColor()` calls

| Token | Use |
|---|---|
| `accentText` | Title / value sitting on an accent fill |
| `accentBody` | Its second line — same colour, dimmed |
| `surfaceText` | Title / value on a panel or pill |
| `surfaceBody` | Its second line |

They are not pure black or white: a tenth of the surface they sit on is mixed
back in, so the piece belongs to the scheme instead of looking punched out of
it. 0.10 is as far as that tint goes before the worst scheme drops under 4.5:1.

**A property may never be named `onSomething`.** QML reads a leading `on` plus a
capital as a signal handler, so `onGhost` was never a property at all and every
caller silently got black.

### Light and dark are one scheme with two faces

`Prefs.themeMode`. A scheme is not inverted for light: matugen ships both faces
at once (a role knows its light and its dark hex) and `Colors` picks by mode, so
switching is a re-pick, not a regeneration. Rules that hold in both:

- Never name `abyss` "the dark one". On a light palette `abyss` is the pale
  background and `snow` is the near-black text. Ask `darkTone` / `lightTone`,
  which sort the two extremes by measured luminance.
- `lightTheme` is the question to ask, never a hardcoded guess.
- The light face is anchored on `surface_dim`, not on the lightest container:
  matugen's light ladder is squashed against white, and a shell built on it has
  no separation between its sheets and no tint from the wallpaper.
- A light accent falls back to its container tone only when that tone still
  clears 4.5:1 against a panel — `ghost` is a *glyph* colour in most of the
  shell, so a pastel accent is an invisible one.

### Opacity roles — five, not twenty-four

| Role | Value | Use |
|---|---|---|
| `inset` | `ghostAlpha(0.06)` | A card recessed into a panel |
| `line` | `ghostAlpha(0.12)` | Dividers, meter tracks, disabled fill |
| `rest` | `ghostAlpha(0.20)` | A chip at rest |
| `hover` | `ghostAlpha(0.30)` | Under the pointer |
| `sunken` | `ghostAlpha(0.45)` | Held / active but not accent-filled |

Backgrounds get **two** values, not nine:

- Panel card — `surfaceAlpha(0.95)`
- Bar pill / utility pill — `surfaceAlpha(0.82)`

---

## 5. Icon vocabulary

One glyph per meaning. These are the canon; the "instead of" column is what is
in the tree today and has to go.

| Meaning | Glyph | Code | Instead of |
|---|---|---|---|
| Close this panel | ✕ | `e5cd` | — |
| Remove **one** thing | ✕ | `e5cd` | 🗑 `e872` (Clipboard), 🗑 `e92e` (net rows) |
| Clear **everything** | ≡ sweep | `e0b8` | `e16c` (Clipboard "Clear all") |
| Expand / collapse | ⌃ / ⌄ | `e5ce` / `e5cf` | — |
| More actions | ⋯ | `e5d3` | — |
| Confirm / done | ✓ | `e876` | — |
| Search | 🔍 | `e8b6` | — |
| Locked | 🔒 | `e897` | — |

"Remove one thing" is **one** meaning, not three. Deleting a clipboard entry,
dismissing a notification and forgetting a Wi-Fi network are the same gesture
from the user's side: *take this off my list*. They all get ✕. No trash can
survives anywhere in the shell — both `e872` and `e92e` are retired.

Hardware and status glyphs, verified by rendering the font — **these were
crossed in `ProcessPanel` until 2026-07-30** (`e322` is a CPU die and was
labelling RAM; `e30d` is a RAM stick and was labelling the GPU):

| Meaning | Code | | Meaning | Code |
|---|---|---|---|---|
| CPU (die) | `e322` | | Temperature | `e1ff` |
| Memory (DIMM) | `e30d` | | Network node | `e335` |
| Storage | `e1db` | | Activity monitor | `eaa2` |
| Display / GPU | `e30a` | | List | `e896` |
| Clipboard | `e14f` | | Copy | `e14d` |
| Image | `e3f4` | | Settings | `e8b8` |

**Never guess a codepoint.** Render it first:

```sh
magick -size 110x110 xc:white \
  -font "/usr/share/fonts/TTF/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf" \
  -pointsize 68 -gravity center -annotate +0+0 "$(python3 -c 'print(chr(0xe322))')" out.png
```

---

## 6. Motion

| Token | ms | Use |
|---|---|---|
| `micro` | 120 | Colour and opacity swaps |
| `hover` | 150 | `Sizes.pillHoverMs` — the hover grow |
| `standard` | 200 | A property moving because you did something |
| `emphasis` | 300 | Something resizing or travelling a distance |
| `arrival` | `Sizes.panelArmMs` / `panelCloseMs` | Panels only — do not hand-roll |

Three curves:

- **`OutCubic`** — the default. Anything arriving.
- **`InOutCubic`** — anything that reverses along the same path.
- **`OutQuint`** — a panel growing out of its pill.

Hover is one function for the whole shell: `Sizes.hoverScale(hovered, pressed)`.
Never write your own scale numbers.

### Overshoot — settled: landing only

`EdgeEntry.qml` used to say "OutQuint, never OutBack" while `DropCard` and
`MediaPanel` both ran `spread` on `OutBack, overshoot: 0.7`. The rule now reads:

> **Overshoot belongs to the landing, never to the journey.**

A drop may flatten as it lands — that is the cross axis widening past its
target and settling back, and it is what makes the media island feel like a
liquid instead of a box. Nothing else bounces: not travel, not growth, not a
whole panel, not a hover.

| Property | Curve | Why |
|---|---|---|
| `fall` (travel) | `OutCubic` | Going somewhere. Arrives and stops. |
| `stretch` (lead axis) | `OutCubic` | The drop elongating as it detaches. |
| `spread` (cross axis) | `OutBack`, overshoot **0.7** | The flatten on impact. |
| `grow` (pill → panel) | `OutQuint` | A whole panel. Never bounces. |

0.7 is the ceiling. It is about five pixels on a 400 px card — felt, not seen.
Anything larger reads as a toy.

### `Prefs.panelStyle` — how a panel arrives is a setting

| Value | Arrival |
|---|---|
| `morph` | The panel grows out of its capsule (`DropCard`) |
| `window` | It unfolds where it lives (`ArriveCard`), capsule or not |

Nothing chooses between them by hand: a panel hands its body to `PanelHost`,
which asks whether the capsule is actually on screen (`Pills.isTool` or
`Prefs.pillVisible`) and picks the card. A panel with no capsule at all always
unfolds, which is what `EdgeEntry` is for.

---

## 6b. Voice — what the shell says

Where another shell leaves a hole or cuts a moment short, Ashen says something.
That is the seal, and it has three parts: **one voice, one moment, one motion.**

**One voice.** Every remark in the shell comes out of `services/Voice.qml`, keyed
by the moment it belongs to (`lock.wrong`, `usb.empty`, `record.start`). Nothing
writes its own pool. Two pools already had to be deleted for growing locally —
`NotificationPanel.emptyLines` and `MediaWidget.quiet` — and that is exactly the
drift the bank exists to stop. Tone: dry, lowercase, more wry than funny. A line
you will read a thousand times cannot be a joke.

**One moment.** The shell is allowed to take a breath where the machine does not
need one — the lock holds for ~2.6 s after the password is right, and says
something, rather than snapping away. Time is part of the character.

**One motion.** A line that belongs to a *moment* or a *wait* is typed out with
`widgets/SaidLine`. A line that fills an *empty panel* is printed whole: watching
a sentence be written every time a drawer opens gets old by the third time.

Three rules that are not negotiable:

- **Never where it has to be read to operate.** Labels, values, Settings rows and
  placeholders that explain a control are not remarks. A launcher placeholder may
  rotate, but every line in the pool still says what to type.
- **One speaking line per surface.** Two at once is a shell chattering.
- **Pick on the edge, never inside a binding.** `Voice.pick()` in a binding
  re-rolls on every re-evaluation, and a line rewriting itself under the cursor
  reads as a list still searching. Pick in `onShownChanged`, `onXChanged`, or a
  property that is initialised once. A property *initialiser* is the usual place,
  which is why `Voice.lastPick` is mutated in place and never reassigned:
  reassigning it notified every one of those initialisers and the log filled with
  binding loops.

For a toast, the label stays the headline and the remark goes underneath:
`addSystemToast(Voice.pick("dnd.on"), glyph, false, "dnd", { title: "DO NOT DISTURB ON" })`.

## 7. Components — use these, don't rewrite them

| Need | Use | Never |
|---|---|---|
| A panel that grows from a bar pill or a utility chip | `widgets/DropCard` | A hand-rolled `fall`/`spread` |
| A panel with no pill behind it | `widgets/EdgeEntry` | Fading in centred |
| A column heading | `widgets/SectionHead` | A bare `Text` at 18–20 px |
| A square icon button | **`widgets/IconButton`** | A private `component XBtn` |
| A transport / utility chip | `widgets/CtlChip` | — |
| A reading between empty and full | `widgets/LiquidPane` (panel) / `LiquidBox` (chip) | A dial, a ring, a bare progress bar |
| A line that may not fit its slot | `widgets/MarqueeText` | `elide` alone, or text that scrolls unprompted |
| A chip on the system pill | `bar/components/SystemChip` | — |
| A row laid along the bar's axis | `bar/components/BarStrip` | A raw `Row`/`Grid` |
| Settings surfaces | `settings/components/*` | — |
| Arranging monitors | `settings/components/MonitorGrid` | A free drag canvas |

**The one thing components/ still has no answer for is a button with a word in
it.** `IconButton` is a glyph in a box. Settings > Display needs Apply and
Revert to say what they do, so it carries a private `ActionBtn` — the fourth
rule says a sixth private copy is never the answer, so if a second surface ever
needs a text button, that is the moment it moves to `components/`.

### The two tiers

Not everything that opens is a panel, and forcing a 40 px icon box onto a 260 px
volume slider would drown it. There are exactly two tiers:

**Popover** — one thing, self-evident, ≤ 320 px wide.
*Volume, Brightness, Battery, Media, Calendar, Power menu, Tray menu.*

- **No header.** The content is the title: a volume slider needs no label
  reading "Volume".
- Opens out of the pill it belongs to, at `cardR`.

**Panel** — several sections, or a list you browse.
*Process, Clipboard, Notifications, Network, Bluetooth, USB, Settings,
Wallpaper, Utilities.*

- **`SectionHead` is required**, one per column, so columns start on one line.
- Body of cards at `cardR`, `inset` fill, 12 px apart, 18 px panel margin.
- Wider than tall → readings left, the live list right. One list → one column.

**Search-first** — one field and what it finds. *Launcher.*

- **No header either.** The search field is the header: it names the surface by
  saying what you may type into it, and a title bar above it would only repeat
  that. This is the one place a `panel`-sized surface goes without a
  `SectionHead`, and only because the field earns its place.
- The field is the surface's largest type (`sectionTitle`), not body text.

Both tiers share the rest:

1. **Arrival** — `DropCard` if something on screen opened it, `EdgeEntry` if not.
2. **Dismissal** — click-off layer at `z: -1`, `Esc` closes, and the window
   stays mapped for `panelCloseMs` so the exit is actually seen.

### Sections of one panel: a travelling accent, no boxes

A panel with sections — Settings' nine, Clipboard's two — moves **one** accent
between them. Not a plate per row lighting up: nine outlines stacked down a
sidebar compete with the content they are supposed to be introducing, and
nothing about them says *picked* rather than *present*. The movement is what
says it, the same way the workspace strip has always worked.

- The indicator is one `Rectangle` at `innerR`, `Colors.ghost`, sliding on
  `SmoothedAnimation` (~260 ms).
- Rows carry **no** background, border or radius of their own. Icon, name, and
  a count if there is one.
- Row text is `fg`: `onColor(ghost)` when picked, `snow` under the pointer,
  `mist` otherwise.
- Vertical where the panel has a sidebar; horizontal only if it genuinely has
  no room for one.

Changing section **cross-fades** the body: `msStandard` (200 ms), `OutCubic`,
from 0. A whole page of different content replaced between two frames reads as
a flinch, not as a move — the indicator slides but the content has to catch up
with it. The indicator's travel and the body's fade run at the same time; the
body does not wait for the accent to arrive.

### Icons name controls, not panels

**A panel gets no icon of its own and no big title.** The 40 px glyph over a
17 px name was the panel repeating the pill you had just clicked — you already
know what you opened, because you opened it.

- **Yes**: an icon on every row of a section rail, on a chip, on a button, on
  the pill. That is where an icon does work: it tells you what a control *is*
  before you read it.
- **No**: a `SectionHead` announcing "Settings", "Clipboard", "Process". If a
  panel needs a word at the top, it is a `meta`-sized line of live detail —
  the CPU model, "12 running · by CPU" — not a title.

`widgets/SectionHead` is kept for a surface that genuinely has to name itself
to a stranger, and nothing in the shell currently does.

### A reading is a vessel with liquid in it

**Anything that is a level between empty and full is shown as water in a box.**
Sound and battery both read this way, and that is the whole reason a panel with
one number in it does not need a dial, a ring or a bar to say what it already
says.

- `widgets/LiquidPane` is the vessel: it takes `value` and whatever the caller
  puts inside it, and re-inks the part of those contents the water has reached
  (`widgets/Submerged`) so nothing ever sits on a tone it shares. Letters,
  a glyph, a whole `SliderTrack` — the slider standing in the water changes
  colour exactly the way the words beside it do.
- `widgets/LiquidBox` is the same idea at chip size, and `widgets/LiquidFill`
  is the surface both are painted with: two sine waves of different length so
  the swell never reads as a sawtooth, on a 33 ms timer rather than every
  frame.
- **The vessel opens empty.** `armed` holds it at zero until the card is really
  on screen and `sweepMs` runs it up from there: the climb is the panel saying
  what it just read, and a box that is already full when it lands says nothing.
- **`glow` is for something that is still happening**, not for something that
  merely is: the battery breathes while it charges and stands still while it
  discharges. It is the same 900/900 pulse the dial's halo had.
- **Never on the bar.** Three canvases painting at 30 fps in the bar measured
  29.5 % CPU against 12.7 % without them. A vessel belongs to a panel, which is
  only alive while it is open.

### Text runs only under the pointer

**A line too long for its slot is cut with an ellipsis, and walks only while
the pointer is on the thing it belongs to** (`widgets/MarqueeText`). A bar with
words sliding about on their own is a bar that never stops moving in the corner
of your eye.

When it does run it runs *continuously* — a second copy follows the first
across a fixed gap, and the reset to zero lands where that copy already is, so
there is no seam. It never walks to the end and reverses: that reads as the
text changing its mind. Linear curve, constant speed, so a longer title takes
longer rather than travelling faster, and one beat at the start of each turn so
the beginning can be read before it leaves.

### A cover that is not playing stands down

Album art is the one part of the media pill that looked identical whether
anything was playing or not. **Paused, it drops to 45 % and the pill says so
without a word.** The dimming multiplies whatever the track-change sweep is
already doing to it, so the two never fight.

### The utility pill

The strip that peeks off whichever screen edges the bar is not using. Its
**ends belong to the pill itself and its middle to the tools**, which is why
both ends are circles and everything between them is a rounded rectangle:

- **Head — pin.** Holds the pill out until pressed again, instead of retracting
  a second and a half after the pointer leaves. For a spell of work where you
  keep reaching for the same tool.
- **Middle — the tools**, sharing whatever length is left over.
- **Tail — the drawer.** The way in to every action the shell has.

A tool chip hands over to the panel it opens (`takenOver`), so while its panel
is up the chip is not drawn: the card grew out of that rect and has to read as
the chip unfolded. Each chip watches **its own** panel — keyed on "any panel
from this edge", opening one would blank the others.

### Where it comes from is not where it goes

Two separate questions, and conflating them is why the launcher was wrong twice.

**Origin** — the thing that was clicked. A bar pill, a chip on the utility pill,
or, for a keybind, that panel's usual slot. A panel always grows out of its
origin: that is what makes it read as the control unfolding instead of a window
appearing. This is the rule with no exceptions.

**Destination** — where it comes to rest. By default it tracks its origin, which
keeps the movement short and the connection obvious. **Two panels pin their
destination instead, for ergonomics, and they are the only two:**

| Panel | Lands | Why |
|---|---|---|
| Launcher | Centre of the screen | You type into it while looking at it, so it goes where your eyes already are — not wherever its opener happened to sit. |
| Notifications | Always the left rail | It used to jump to the right whenever the bar moved there, so the place you look for your notifications changed with an unrelated setting. |

A panel whose destination is pinned may travel a long way, and the goo neck
does not survive the trip — stretched over half a screen it stops reading as
something being pulled apart and becomes a rope. Those set
`DropCard.neckEnabled: false`.

Adding a third pinned panel needs a reason as good as these two. The default is
to track the origin.

### `IconButton` — the one small button

One component, **one look**: a filled plate, always. A button with no background
until you touch it is a button you have to hunt for, and the shell had four
variations on that theme.

| State | Fill | Glyph |
|---|---|---|
| Rest | `ghostAlpha(0.20)` | `ash` |
| Hover | `ghostAlpha(0.30)` | `snow` |
| Active / on | `ghost` solid | `Colors.onColor(ghost)` |
| Unavailable | `ghostAlpha(0.08)` | `ash` at 40 % |

- Sides: **24**, **28**, **32**. Nothing else.
- Radius `innerR` (8) at every size.
- Glyph: 14 / 16 / 18, matching the side.
- Hover motion: `Sizes.hoverScale()` over `pillHoverMs`. Always.
- **Never closer than `Sizes.btnGap` (6 px) to another button.** Two buttons
  tighter than that read as one control with a seam — and because every button
  grows under the pointer, a hovered one at a 2 px gap touches its neighbour.
  The notification header ran at `spacing: 0` with three buttons in a row.

A button that only exists on hover (the delete on a list row) keeps the filled
look — it fades in *as* a plate rather than as a bare glyph. **List rows must
gate it on row hover**: sixteen filled plates down the right of a list read as a
column of buttons rather than as a list. `Clipboard`, `ProcessPanel` and
`NotificationPanel` all do this.

This replaces `IconBtn`, `CloseBtn`, `StepBtn`, `DeleteBtn` and the two inline
copies. `CtlChip` stays only if the transport buttons genuinely need behaviour
`IconButton` cannot express; otherwise it folds in too.

---

## 8. Folder layout

**Done.** `modules/bar/` used to hold twenty files that mixed the bar itself
with panels that have nothing to do with it — `ProcessPanel` opens from a
utility pill, not the bar, and `Clipboard`/`Launcher` already had their own
folders while `NetworkPanel` and `PowerMenu` did not. The fifteen panels now
live in `modules/panels/`; `modules/bar/` is `Bar.qml` and its `components/`.

```
modules/
  bar/            the bar surface and the pills that live on it
    components/   pills and chips — bar furniture only
  panels/         every panel, whatever opens it
  widgets/        shared primitives with no feature knowledge
  settings/       the settings window
    components/   surfaces used only by settings
  lock/           the session lock surface
  net/            rows shared by the network and bluetooth panels
  desktop/        the layer on the wallpaper
    widgets/      one file per desktop widget
services/         singletons: state, hardware, theme, geometry
```

Rule: a file goes in `widgets/` only if it knows nothing about the feature using
it. `SectionHead` qualifies; `NotifRow` does not.

### The desktop layer

Widgets sit on `WlrLayer.Bottom` above the wallpaper and below every window:
furniture, not an overlay. Three rules hold it together.

**It takes no clicks except where something can be pressed.** In rest the
layer's mask is cut to the boxes of the widgets that say `wantsInput` -- today
the music transport -- and nothing else, so a click anywhere else on the desktop
goes wherever it went before and no widget can be shoved by accident. A shape
with nothing to press (the lyric page) asks for no hole: one over it would eat
clicks meant for the wallpaper. `Super+Shift+D`, `ashen-widgets`, or Arrange in
Settings turns dragging on and opens the whole screen; Escape turns it off. That
is also the only time a widget wears an outline.

Those boxes live in `Desktop.inputMap`, **reassigned and never written in
place**: the region is bound to it, and a map mutated in place never tells the
binding to re-cut.

**A canvas on the desktop paints only while the desktop is seen.** Everything
that runs on a clock — the spectrum, a trend — hangs off `live`, which is false
behind a fullscreen window. The bar learned this the expensive way: three
canvases at 30 fps cost 29.5 % CPU against 12.68 %.

**Never call a window `layer`.** Every `Item` has a `layer` group of its own and
inside a `Component` that one wins over the outer id, so `layer.something` comes
back undefined with no error worth the name. Same family as naming a property
`focus`.

### A widget's shape is a field, not a file

Every desktop widget declares its shapes in `Desktop.catalogue`, and the chosen
one is a field of its record beside `x`, `y` and `on`. Two things fall out of
that for free: the row of shapes offered while arranging is generated, and a
wallpaper profile carries the shapes with it, because the record it already
saves is where they live.

The row itself is drawn by the layer, never inside the widget: Qt does not
deliver mouse events to anything painted outside its ancestors' bounds, so a
strip hanging off a widget's own bottom edge would be visible and dead.

While arranging, `Free` drops a widget where the hand left it, `Grid` rounds to
`Desktop.gridStep`, and `Magnet` puts it beside its nearest neighbour with
`Desktop.magnetGap` between them, lining the two up on the other axis so they
read as one row. Nothing can end up closer than that gap. The guides are drawn
only in the mode you can land on, and none of the three is saved -- how you are
arranging is not part of the look.

**A widget can have two axes.** `styles` says how much it shows; `skins` says
how it draws -- the system widget is Large/Medium/Compact crossed with Water or
Chart -- and the dry skin draws a reading with a past as the same stepped curve
the day's temperature wears, a reading without one as a flat bar. A ring was
tried there and pulled against the chart beside it. Both are fields of its record, so the chips are generated and a wallpaper
profile carries them without anything else being told. A widget with no `skins`
never hears about the second row.

**A widget is content, never a card.** The plate belongs to `DesktopWidget`;
anything drawing its own opaque box inside it is the double plate this shell
threw out. The Process panel's cards ARE its surface -- out here there is
already one underneath, so what carries over is the vocabulary (a glyph with a
spaced NAME, the figure on the right, a past as a curve, a level as liquid) and
not the box.

### A cover, and the words

`MediaArt` decides what a surface draws, and the surfaces only draw it: the
player's own file while it is real, and iTunes' answer when the player gives
nothing or gives its own logo -- which the service already recognises by the
cover turning up under two unrelated albums. A good cover is never overruled;
the card and the pill stopped each keeping their own copy of that reasoning.

The lyrics are a **column of the card**, not a drawer under it. A drawer made
the words something you had to ask for twice, and what a card is about should
be on the card. The column and the cava beside it are **one block**: half the
card's gap between them, the whole of it from the controls -- they are the same
thing said twice, the words and what they sound like. No words for this track
and the column takes its width back, so the panel is exactly as wide as it has
to be; the card measures itself (`implicitWidth`) and the panel's `openW` reads
that, so the box grows WITH the column instead of stepping once.

A column can be turned off (`Prefs.mediaLyrics`, the chip on the card or
Settings), and that answer is remembered. The chip only exists where there is a
column to hide.

**A gap that can close travels inside a width, never in a layout's `spacing`.**
A layout charges its spacing for a child of no width too, so a closed column
would leave a hole where it used to be.

**The wave says the sound, and the dot says the place.** The progress line is a
sine whose played half moves, with its height driven by the live cava level --
a quiet passage flattens it, a drop swells it. What is still to come is a
straight dim rule starting AT the playhead: a rule running under the wave
crosses it twice per crest and reads as a seam. The wave is tapered to nothing
over the last 30 px so it lands ON that rule instead of stopping mid-crest --
that step was the break no round cap could hide -- and because a tapered end is
too thin to point at, the playhead itself is a dot with a ring of plate under
it.

**Cava is drawn in the accent, never mixed into the plate.** Silence is said by
the bars collapsing onto their axis; dimming the colour as well says it twice
and leaves a picture of a visualiser rather than one.

### Where a setting lives

The wallpaper belongs with the desktop, not with the palette. Settings › Desktop
holds the picture, its folder, the widgets, the pictures on it, and which look
this wallpaper remembers; Settings › Appearance keeps what the shell itself
looks like -- the scheme, the accent's gradient, how panels open. Before the
split, one tab held both and was the biggest thing in the drawer.

### A look belongs to a wallpaper

`Services.Looks` keeps one profile per wallpaper path, opt-in per wallpaper. A
profile is a photograph of the settings named in `Looks.keys` plus the two the
theme keeps outside Prefs (the scheme and the dynamic style) — so adding
something to what a wallpaper remembers is one line in that list, and nothing
else has to know its name.

A wallpaper nobody remembered wears `Looks.baseline` -- the default look, set
from whatever is on screen in Settings, and the classic (no widgets, `pills`
bar) until someone saves one. Without it, putting on a plain wallpaper left the
last one's widgets and bar sitting there, and the whole feature read as not
remembering anything.

The order matters: `ashen-wallpaper.sh` runs matugen itself and reads the mode
and the style off disk, so the picker stages the profile **before** it starts
the script. A wallpaper that arrives any other way is reconciled afterwards, at
the cost of one more matugen run.

---

## 9. Backlog — what deviates today

Ordered by how much each buys.

1. ~~**`widgets/IconButton`**~~ — **done.** One filled component at 24 / 28 / 32.
   Replaced `IconBtn` (NotificationPanel, 6 call sites), `CloseBtn`
   (NotificationToast), `DeleteBtn` (Clipboard, 2), the inline kill button
   (ProcessPanel), and `StepBtn`, which survives only as a thin named wrapper
   for its 8 settings call sites. `CtlChip` was kept — the media morph
   interpolates its size continuously, which the fixed ladder cannot express —
   but its palette was aligned: hover and active used to *share* the solid
   accent fill, so a hovered pause button looked identical to a playing one.
2. ~~**Icon vocabulary**~~ — **done.** `Clipboard` delete `e872`→`e5cd`,
   clear-all `e16c`→`e0b8`; `BtDeviceRow`, `WifiNetworkRow` and
   `SettingsWifiTab` forget `e92e`→`e5cd`. **No trash can survives anywhere in
   the shell** — verified by scan.
3. **Tokens in code** — add the type/shape/opacity/motion ladders to
   `services/Sizes.qml` (or a new `Tokens.qml`) so the rules are reachable from
   QML instead of living only in this file.
4. **Panel headers** — sort every surface into a tier, then make it obey.
   Panels that title themselves differently today: `BluetoothPanel` (20 px),
   `USBPanel` (18 px bold), `NotificationPanel` (20 px), `Launcher` (20 px),
   `BrightnessPanel` (18 px, not bold — and it is a popover, so its title goes
   entirely). `NetworkPanel` is a panel with no header at all.
5. ~~**Card backgrounds**~~ — **done.** Twenty-seven call sites across eight
   alpha values collapsed onto `surfacePanel` and `surfacePill`. One
   `surfaceAlpha` survives on purpose: the veil over a wallpaper thumbnail that
   has not decoded yet, which is not a card background.
6. **Settle the overshoot question** (§6), then make every arrival obey it.
7. ~~**Folder move**~~ (§8) — **done.** It touched exactly one import:
   `shell.qml` now imports `root:/modules/panels` alongside `root:/modules/bar`.
   No panel referenced a bar component.
8. ~~**The goo neck exists four times**~~ — **done.** `widgets/GooNeck` takes
   numbers (the two edges, the pill width, the pinch) rather than reading
   services, so the bar's panels and the ones hanging off a screen-edge peek
   share it. The 30 px floor on the neck's width, which only `DropCard` had,
   now applies to all four — the hand-written copies drew a hairline off a
   small chip.

9. **`TrayMenu` is the last panel outside `PanelHost`** — it still runs the
   origin-anchored `Scale` from July. It is not a straight migration: it has no
   entry in `Pills`, its origin is a tray icon whose rect arrives at runtime,
   and its height is its content's. `PanelHost` would need a way to be handed a
   rect directly instead of deriving one from a capsule.
10. ~~**Apps outside the shell keep matugen's `primary` in light mode**~~ —
   **done.** A matugen template cannot measure contrast, so the choice is made
   once in `scripts/ashen-accent.sh` and everyone reads the result: every
   template now carries `__ASHEN_ACCENT__` / `__ASHEN_ON_ACCENT__` (and the `2`
   pair for the secondary) where it used to carry a colour, and that script
   substitutes them the moment matugen returns. It also owns the kitty and
   portal-gtk reloads — a matugen `post_hook` fires while the other templates
   are still unsubstituted, so there are no `post_hook`s left in `config.toml`.
   The window border reads the same resolved hex, so the shell, the apps and
   Hyprland cannot disagree by construction. Kitty's *selection* pair is the one
   deliberate holdout: its foreground is `surface_dim`, readable against the
   strong tone only.
11. **Hover** — settled. Nothing lights up under the pointer: it grows and its
   contents lift to `snow`. There is no hover fill token anywhere. The bar had
   five different tint strengths for the one gesture before this.

---

## 10. Checklist for a new panel

- [ ] Opens through `PanelHost` (it picks `DropCard` / `ArriveCard`), or
      `EdgeEntry` if it never had a capsule
- [ ] Header is `SectionHead`; one per column
- [ ] Every size from §2, every radius from §3, every opacity from §4
- [ ] Icons from §5, rendered and checked before committing
- [ ] Durations and curves from §6; hover via `Sizes.hoverScale`
- [ ] Buttons reuse `IconButton` / `CtlChip`
- [ ] A level between empty and full is a `LiquidPane`, armed so it opens empty
- [ ] Every box is a rounded rectangle or a circle — nothing else
- [ ] Nothing destructive is red
- [ ] `Esc` closes it; click-off closes it; the exit animation is visible
- [ ] Works on a bar at all four edges, and on a second monitor
