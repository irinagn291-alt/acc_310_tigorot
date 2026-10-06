<!-- gf-brief source=621bfe7511ac62ff7be4be4081d780546001a118aa03216a0e5802c07fd2fc6f written=2026-10-06T19:48:48+03:00 -->
# Tigorot
## What it is
Tigorot is a portrait quiz for people who keep paintings from the Copenhagen collection of Statens Museum for Kunst on this device. Home is a single quire: Echo prints the maker or the picture title with one word copied beside itself, and only that surplus copy files the work. There is no shop, no grade, and no account.

## Launch and onboarding
A cold launch shows the system launch screen, then the native quire.

On a physical device with no saved session, a three-page cover appears over home. Each page has art, a title, a line, a full-width primary button, and **Skip**.

1. **Save a painting** — “Gather works from Copenhagen. The quiz only sits on what you keep here.” Primary button: **Continue**.
2. **Echo the line** — “Echo prints maker or picture, one field, with one word copied beside itself.” Primary button: **Continue**.
3. **Tap the copy** — “The surplus word files the work. A miss greys that word and stays on the quire.” Primary button: **Next**.

**Skip** on any page, **Continue** on pages 1–2, and **Next** on page 3 all finish the cover and leave the person on home. The cover does not ask for an account or a permission.

On Simulator, the first launch skips that cover, keeps four local paintings, and already prints a live doubled line so the first word tap can file.

After the cover is done, later launches open straight on the quire. **Re-run onboarding** in Settings shows the same three pages again without wiping paintings or marks.

## Screens
Home is the locked quire. There is no tab bar. **Explore**, **Saved**, **Settings**, and **The extra copy** open as sheets over home. Each sheet has a trailing close control (VoiceOver: **Close explore**, **Close saved**, **Close settings**, **Close the extra copy**).

### Home (quire)
The top title changes with the fold:

- **Echo a work** when nothing is live yet
- **Tap the copy** when a doubled line is up
- **Painting filed** after a correct tap
- **Quire is fair** when nothing left can be echoed

Icon buttons **Explore**, **Saved**, and **Settings** open those sheets.

**Empty / fair.** When no usable saved painting is waiting, the body is a full page: **Quire is fair.** / “Save a work, then sit the quiz.” / **Explore**. That button opens the Explore sheet.

**Populated.** A large painting tile (photograph when the work has one, otherwise a decorative plate). After a correct file, a success mark sits on the tile. Under the tile:

- The painting title, or **Echo a saved painting** if none is focused
- The maker name on the line below, or “Save a work, then sit the quiz.” if none is focused
- A horizontal row of word chips from the echoed field, with one word appearing twice in a row, and the caption **Tap the copied word.**
- If Echo has not printed a line yet: “Echo prints the doubled line here.”

Word chips: each chip shows that word. A miss greys the chip and adds the label **Dwell** under it. Tapping the surplus copy files the painting, adds one to **Filed paintings**, and moves the title to **Painting filed**. Tapping any other word only greys that word and stays on the same line. Grey **Dwell** chips do not accept another tap. All chips are inert unless the title is **Tap the copy**.

**Echo** (full-width pill) prints the next unused saved painting whose title or maker has at least two words. It is hidden while the line is live. It is disabled, and may show a spinner, while a write is in flight or when no unused usable painting remains.

**The extra copy** opens the twist sheet.

A small rail of up to two saved-painting thumbnails sits beside the **Filed paintings** count (the number of successful files).

**Undo** peels the newest file or miss. Disabled when there are no marks.

A successful file plays a short confirmation haptic. A miss does not.

### Explore
Title: **Explore**. Search field prompt: **Search the catalog**.

On open, the list fills with the last catalog results if any, otherwise the local Copenhagen shelf. Each row is the painting title over the maker. Tapping a row keeps that painting on this device (or focuses it if it is already kept) and dismisses the sheet back to the quire.

**Empty.** **Shelf is quiet.** / “Search Copenhagen, or keep a local painting.” / **Show shelf** fills the list with the local shelf.

**Hunt missed.** **Hunt missed.** / “The catalog did not answer. Keep a local painting or try again.” / **Try again**. This page only appears when a hunt fails and there is nothing local to show.

Typing in search hunts the Copenhagen catalog. Clearing the field restores the last results or the local shelf. A hunt that returns no rows still hangs from those same local paintings, so the list does not go blank after a fruitless search. A spinner appears only if the hunt lasts more than a moment.

### Saved
Title: **Saved**.

**Empty.** **No marks yet.** / “File a surplus copy, then review cancels and dwells here.” / **Back to quire** closes the sheet.

**Populated**, in this order when each group has rows:

- **Expunged** — filed painting title, maker, and a medium-style day
- **CancelMarks** — painting title (or **Work** if the title is gone), kind **Cancel**, and the day
- **DwellMarks** — painting title (or **Work**), kind **Dwell**, and the day

Rows are read-only.

**Ledger slipped.** **Ledger slipped.** / “The saved quire could not be read. Echo again after a reset, or peel a mark.” / **Undo** (disabled if there is no mark). This is the Saved error page when the kept quire could not be read and no paintings are in memory.

### Settings
Title: **Settings**.

Optional top notes (only one of these):

- “A write missed the vault. Peel a mark or reset if the quire stays stale.”
- “No marks sit on this device yet. Echo a painting from home first.” (only when there are no kept paintings and no files)

**Collection**

- **Statens Museum for Kunst** — opens the museum’s public site
- **SMK Open** — opens the museum’s Open page

**Marks**

- **Undo** — same peel as on home; disabled when there is no mark
- “Cancels *n*. Dwells *n*.” with locale-formatted whole numbers

**Help**

- **Contact us** — opens the support page
- **Re-run onboarding** — closes Settings and shows the three-page cover again

**Reset all data** opens a confirmation: “Reset all saved paintings, marks, and the live line on this device?”

- **Reset all data** — wipes paintings, marks, and the live line on this device, then the cover can appear again
- **Keep quire** — dismisses the confirmation

### The extra copy
Title: **The extra copy**.

**Echo then expunge** — “Echo copies one native word beside itself. Only that surplus copy files the painting. A miss greys the word and keeps the line up.”

**Back to quire** (and the close control) return to home. This sheet does not Echo or file by itself.

## Features
- Gather paintings from Copenhagen (catalog search or the local shelf) and keep them on this device
- Quiz only sits on paintings the person has kept
- **Echo** prints maker or picture, one field, with one word copied beside itself
- **Tap the copied word** to file that painting
- A miss greys that word, labels it **Dwell**, and stays on the quire
- **Painting filed** / **Filed paintings** after a surplus tap
- **Undo** peels the newest file or miss
- **Saved** lists **Expunged** paintings, **CancelMarks**, and **DwellMarks**
- **The extra copy** / **Echo then expunge** explains the job
- One-shot onboarding with **Skip**, re-runnable from Settings
- Collection credit for **Statens Museum for Kunst** and **SMK Open**
- **Contact us**
- **Reset all data** on this device
- Light appearance, portrait quire with no tab bar

## Behaviours that can look like bugs
- Home opens on **Quire is fair.** / “Save a work, then sit the quiz.” until at least one usable painting is kept. Tap **Explore**, pick a painting, return, then tap **Echo**.
- **Echo** stays disabled when every kept painting is already filed, or when the only kept works have a one-word title and a one-word maker. Keep another painting from Explore, or tap **Undo** to un-file the newest one.
- **Echo** is hidden while the title is **Tap the copy**. Finish the line (surplus tap) or stay on that line; a second Echo is refused on purpose.
- **Echo** can show a spinner and refuse a second tap while a write is in flight. Wait until the pill is enabled again.
- Word chips do nothing before **Echo** and after **Painting filed**. They only accept taps when the title is **Tap the copy**.
- Tapping a word that is not the extra copy greys it, shows **Dwell**, and does not file. That is a miss. Keep tapping other words; only the surplus copy files.
- A grey **Dwell** chip refuses further taps. Use **Undo** to undim the newest miss, or tap a different word.
- After a file the same painting stays on the tile. The quiz does not advance by itself. Tap **Echo** again if another unused painting is waiting.
- **Undo** is disabled until a file or a miss exists. File a surplus copy or miss first.
- Tapping a painting already on the quire in Explore only focuses it and closes the sheet. It does not add a second row and does not reset a live line.
- A catalog hunt that finds nothing still shows the local shelf or the last results. That can look like search did nothing. The empty-hunt error page is **Hunt missed.**, and only when there is also nothing local to show; then use **Try again** or **Show shelf**.
- **Shelf is quiet.** can flash before the local shelf or last results fill in. **Show shelf** forces the local list.
- Settings **Undo** is the same peel as home. Error copy that says “peel a mark” means this **Undo** control.
- **Reset all data** does not run until the confirmation. **Keep quire** leaves everything as it was.
- **Re-run onboarding** loops the same three pages. **Skip**, **Continue**, or **Next** returns to the quire with existing paintings still there.
- **Ledger slipped.** on Saved means the kept quire could not be read. **Undo** if a mark exists, or **Reset all data** in Settings, then Echo again.
- “A write missed the vault…” in Settings means a save did not stick. **Undo** or **Reset all data** if the quire stays stale.

## Starter content and resume
Local Copenhagen shelf (also what **Show shelf** loads), each row title then maker:

- View from Dosseringen near the Sortedam Lake — Christen Kobke
- The Isle of the Dead — Arnold Bocklin
- Interior with a young woman seen from the back — Vilhelm Hammershoi
- A View through Three of the North Western Arches — C W Eckersberg

A one-word shelf row (Solo — OneName) is not offered as echoable.

On Simulator only, the first launch already keeps the four echoable shelf paintings, skips the cover, and Echoes the first of them. For that first line the title is **View from Dosseringen near the Sortedam Lake**, the maker line is **Christen Kobke**, the words are View, View, from, Dosseringen, near, the, Sortedam, Lake, and the extra copy is the second **View**.

Catalog search can add further public paintings from the same museum; those titles and makers come from the catalog.

Unfinished work resumes. Kept paintings, the live doubled line, files, misses, and whether the cover has been finished all return after a relaunch. **Reset all data** is the way to start from an empty device.

## Permissions
None.

## Absent
Genuinely absent: login or accounts, in-app purchase, ads, analytics, user-generated content, an account deletion flow, and an App Tracking Transparency prompt. **Reset all data** only clears this device; it is not an account deletion flow.

## Data and support
Paintings, marks, and the live line stay on this device. Explore can fetch catalog listings; what the person keeps is stored here.

Support control: **Contact us** in Settings, under **Help**. It opens the support page. Collection credit is **Statens Museum for Kunst** and **SMK Open**.

## Scanning and health
None. There is no barcode or QR scan. Search is a typed catalog hunt. The app does not show health, medical, or product-health information.

## Platform
English UI only. Counts and Saved day labels follow the device locale (medium date). No region lock; the catalog and shelf are Copenhagen / Statens Museum for Kunst.

Portrait only on iPhone and iPad, light appearance, full screen. Minimum iOS 17.0.

## Category
Education
