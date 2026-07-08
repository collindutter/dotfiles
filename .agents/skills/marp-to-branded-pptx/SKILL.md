---
name: marp-to-branded-pptx
description: Convert a Marp markdown deck into a fully editable, on-brand PowerPoint (.pptx) built on a Google Slides template's native layouts, carrying speaker notes across, ready to upload to Google Slides. Use when someone wants a Marp deck "in Google Slides", "in the company template", or "as an editable branded deck" rather than rasterized slide images.
allowed-tools: Bash Read Edit Write
---

# Marp deck to branded, editable Google Slides pptx

Turns a Marp `presentation.md` into a `.pptx` that reuses a Google Slides
template's layouts, theme, and backgrounds, with real editable text and the
Marp speaker notes preserved. Import the result into Google Slides
(Drive upload, then "Open with Google Slides").

This is different from `marp --pptx`, which bakes each slide into an image, and
from `marp --pptx-editable`, which needs LibreOffice and drops speaker notes.
Here the slides are generated natively with `python-pptx`, so they inherit the
template's design and stay fully editable.

## Reference implementation

A working generator is bundled with this skill at `build_gslides_pptx.py`
(same directory as this SKILL.md). Reuse or adapt it:

```
./build_gslides_pptx.py \
  --md path/to/presentation.md \
  --template path/to/brand-template.pptx \
  --out path/to/output.pptx
```

It runs via a `uv` shebang (`uv run --with python-pptx --with lxml`), so
dependencies install automatically. Use `--drop-cover` to omit the template's
branded cover slide.

## How it works (adapt these when the template differs)

1. **Parse `presentation.md`.** Split on `\n---\n`. For each slide pull:
   the `<!-- _class: X -->` directive, the speaker-notes comment (the comment
   block that does not start with `_`), the headings (`#`/`##` and `>` become
   the title), and the body (paragraphs, `<ul>`/`<li>`, `<p class="fine">`).
   Convert inline `**bold**`, `<strong>`, `*italic*`, `<em>`, `<br>` to styled
   runs.
2. **Pick template layouts by rendered appearance, not by name.** Google Slides
   export layout names are duplicated junk (`MAIN_POINT_1_1_1_1_...`). Render
   one slide per layout to PDF/PNG and look. Grab the content layout from a
   sample content slide in the template (`prs.slides[i].slide_layout`), and
   find the title/section layouts by the clean names that do exist (`TITLE`,
   `SECTION_HEADER`).
3. **Map `_class` to layouts.** In this deck: `title` to the dark `TITLE`
   layout, `section`/`spine`/`quote` to the dark `SECTION_HEADER` layout,
   everything else to the white headline+body content layout.
4. **Fix placeholder collisions.** Template title/subtitle boxes often assume a
   one-line title; reposition and enable `MSO_AUTO_SIZE.TEXT_TO_FIT_SHAPE` so
   multi-line titles do not overlap the subtitle.
5. **Emphasis color.** Map `**bold**` to the template's accent color (read it
   from `ppt/theme/theme1.xml`, e.g. `accent4`) so emphasis reads as brand, not
   just bold.
6. **Delete the template's sample slides** (keep the layouts/masters) via the
   `_sldIdLst` XML; optionally keep the branded cover.
7. **Carry notes** with `slide.notes_slide.notes_text_frame.text`.

## Verifying the output

Render to a contact sheet and eyeball every slide before declaring done:

```
soffice --headless --convert-to pdf --outdir /tmp out.pptx   # needs LibreOffice
pdftoppm -png -r 42 /tmp/out.pdf /tmp/out                     # needs poppler
montage /tmp/out-*.png -tile 4x -geometry +3+3 /tmp/grid.png  # needs imagemagick
```

Read `grid.png` and check for overlaps, overflow, and empty placeholders.
Confirm notes and editability by reopening the `.pptx` with `python-pptx`.
