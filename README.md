# Dittography

A scribe taps the extra copied word on a saved painting to file that work.

Dittography is for people who already keep museum paintings on this device and want to cancel a scribal double. Explore saves works from Statens Museum for Kunst. Quiz sits on those saved works. There is no shop and no grade.

## Why an ADT fold

The quire is Idle, Echoed, or Expunged. Fair is only the empty echo pool. Echo samples a painting that is not Expunged, prints artist or title with one native word written twice in a row, and folds Idle to Echoed. Expunge writes a CancelMark only on that surplus copy and folds Echoed to Expunged. A miss writes a DwellMark and keeps the line. One `QuireStore` pattern-matches the fold so Quiz never keeps a second status enum.

## Echo then expunge

Pick this app when the extra word is this work's own field copied in place, not a word lifted from another painting. Home is the quire: a painting tile, then the doubled line. Tap the surplus copy to file. A miss greys that word and stays. Launch already prints a live Dittograph so the first tap can file. Saved lists CancelMarks with DwellMarks. Settings credits Statens Museum for Kunst.

Explore, Saved, and Settings arrive as sheets. `-ReviewScreen today|log|goals` are launch keys, not tabs.

## Art

Style: 3D glass render glassmorphism. Assets are generated later by `assets.generate` into the empty `dtg_` imagesets. Base prompt:

```
3D glass render, glassmorphism, soft studio light, frosted translucent quire gathering, one doubled folio leaf, refraction and soft bloom, isolated subjects, quiet uncluttered ground, no text, no letters, no logo, no photoreal stock, no specified colours, one scribal gathering not a museum grid
```

## How this app differs

Nearby art quizzes hang a stray, cross a grid, pair a slip, or hook a cartel. Dittography files only the surplus copy of a word that already belongs to the echoed field.

## Build

```bash
cd Dittography
xcodegen generate
xcodebuild -scheme Dittography -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```
