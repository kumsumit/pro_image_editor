# Pro Feature Checklist

This checklist is the product contract for growing ProImageEditor into a
complete professional image editor. A feature is complete only when all three
QA checks pass:

- Present: users can find and start the feature from the editor or documented
  integration API.
- Works correctly: the feature produces accurate previews and final output on
  mobile, desktop, and web where the package supports the platform.
- Non-destructive/export-safe: the edit remains undoable or editable until
  export, and the exported image matches the preview at the configured size,
  format, and quality.

Status values:

- Current: first-party support exists in the package today.
- Partial: the package has some support, but the professional definition below
  is not complete yet.
- Extension: the package exposes integration points or examples, but the host
  app must provide the implementation.
- Planned: no complete first-party implementation is present yet.

## Core Editing

| Feature | Status | Present | Works correctly | Non-destructive/export-safe | Complete requirement |
|---|---|---:|---:|---:|---|
| Crop and straighten | Partial | [ ] | [ ] | [ ] | Free crop, fixed ratios, oval/rect crop, rotation, flip, tilt/horizon straighten, perspective-aware crop, canvas resize, and safe-area overlays. |
| Basic adjustments | Partial | [ ] | [ ] | [ ] | Brightness, contrast, exposure, highlights, shadows, whites, blacks, temperature, tint, saturation, vibrance, and sharpening with sliders and reset controls. |
| Curves and levels | Planned | [ ] | [ ] | [ ] | RGB and per-channel curves, black/white point controls, histogram-guided edits, auto-correct, and numeric inputs. |
| HSL and color grading | Partial | [ ] | [ ] | [ ] | Hue, saturation, luminance per color range, split toning or color wheels, selective color edits, and skin-tone-safe controls. |

## Retouching

| Feature | Status | Present | Works correctly | Non-destructive/export-safe | Complete requirement |
|---|---|---:|---:|---:|---|
| Healing and clone tools | Partial | [ ] | [ ] | [ ] | Healing brush, spot heal, clone stamp, patch-like repair, blemish cleanup, and edge-aware sampling. |
| Object removal | Partial | [ ] | [ ] | [ ] | Brush selection, content-aware fill behavior, cleanup preview, and believable background reconstruction. |
| Blur and depth tools | Partial | [ ] | [ ] | [ ] | Selective blur, lens blur, background blur, focal-point control, bokeh styles, feathering, and editable blur masks. |
| Face and portrait retouch | Planned | [ ] | [ ] | [ ] | Skin smoothing, teeth whitening, eye enhancement, stray-hair cleanup, face-shape controls, and natural-strength sliders. |

## Layers and Selection

| Feature | Status | Present | Works correctly | Non-destructive/export-safe | Complete requirement |
|---|---|---:|---:|---:|---|
| Layer system | Partial | [ ] | [ ] | [ ] | Raster, text, shape/widget/sticker/paint layers, reorder, lock, hide, duplicate, group, opacity, blending modes, and adjustment layers. |
| Masking | Planned | [ ] | [ ] | [ ] | Layer masks, brush masks, gradient masks, invert mask, refine edges, subject/background masks, and mask preview. |
| Selections | Partial | [ ] | [ ] | [ ] | Rectangle, ellipse/oval crop, lasso, polygon, magic wand or color range, edge refinement, feather, expand/contract, inverse, and save/load selection. |
| Transform and warp | Partial | [ ] | [ ] | [ ] | Scale, rotate, skew, distort, perspective transform, mesh/warp tools, and alignment guides. |

## Creative Tools

| Feature | Status | Present | Works correctly | Non-destructive/export-safe | Complete requirement |
|---|---|---:|---:|---:|---|
| Filters and effects | Current | [ ] | [ ] | [ ] | Custom filters, reusable presets, effect stacking, opacity control, before/after preview, and per-effect masking. |
| Text and typography | Partial | [ ] | [ ] | [ ] | Text insertion, font, spacing, stroke, shadow, alignment, warp, and text-on-path. |
| Draw and paint | Partial | [ ] | [ ] | [ ] | Brush engine, eraser, opacity/flow, blend behavior, tablet-aware input where supported, shapes, and color picker. |
| Collage and layout | Partial | [ ] | [ ] | [ ] | Grid layouts, multi-image canvas, frames, spacing controls, and template-based layouts. |

## Pro Workflow

| Feature | Status | Present | Works correctly | Non-destructive/export-safe | Complete requirement |
|---|---|---:|---:|---:|---|
| RAW and format support | Partial | [ ] | [ ] | [ ] | Import/export JPEG, PNG, TIFF, BMP, GIF, PDF, camera RAW where possible, color fidelity, and metadata preservation. |
| Import, export, and sharing | Partial | [ ] | [ ] | [ ] | Export presets, platform resize presets, quality/compression controls, print-ready output, transparent export, watermark options, and share/app integration. |
| Organization | Planned | [ ] | [ ] | [ ] | Thumbnails, albums, keywords, ratings, search, archive support, and batch handling for image collections. |
| Batch editing | Planned | [ ] | [ ] | [ ] | Copy/paste adjustments, preset sync, multi-export, rename rules, and resize/output pipelines. |

## Advanced Checklist

| Feature area | Status | Present | Works correctly | Non-destructive/export-safe | Complete requirement |
|---|---|---:|---:|---:|---|
| Non-destructive editing | Partial | [ ] | [ ] | [ ] | Undo/redo history, editable adjustments, masks, layer-based changes, and reset per tool. |
| Precision UI | Partial | [ ] | [ ] | [ ] | Zoom, pan, ruler/guides, snapping, numeric inputs, keyboard shortcuts, and before/after compare. |
| AI tools | Extension | [ ] | [ ] | [ ] | Background removal, enhancer, generative expand, object erase, and smart selection with manual correction controls. |
| Pro photography | Planned | [ ] | [ ] | [ ] | HDR merge, focus stacking, panorama stitching, and tethered or advanced camera workflow where relevant. |
| Output quality | Partial | [ ] | [ ] | [ ] | High-resolution save, print-ready export, transparent PNG, color-safe resizing, and format conversion. |
| Reliability | Partial | [ ] | [ ] | [ ] | Fast previews, crash recovery, autosave, large-image handling, memory optimization, and accurate rendering at export. |

## Current Package Coverage Notes

The package already includes first-party modules for crop/rotate/tilt, tune
adjustments, filters, blur, paint, text, emoji/stickers, collage, layer
interaction, helper lines, zoom, history, and multi-threaded image generation.
Image generation currently supports configurable output formats including JPG,
PNG, TIFF, BMP, CUR, PVR, TGA, and ICO.

Step 1 hardening now includes automated checks for all configured image encoder
formats, full non-destructive history export/import round trips, crop overlay
rendering, and image conversion with a real widget context.

Step 2 adds serializable `EditorSelection` and `LayerMask` primitives. Masks
are now part of layer state, layer copying, minified import/export, and
non-destructive history round trips. UI tools for drawing/refining those masks
are still the next slice of the masking epic.

Step 3 adds serializable advanced color-adjustment primitives for RGB and
per-channel curves, levels, HSL color ranges, and shadow/midtone/highlight
color-grading wheels. These payloads are preserved by `TuneAdjustmentMatrix`
copying and state-history import/export, including zero-value adjustments that
carry editable pro color data. The follow-up renderer slice adds exact CPU
processing for curves, gamma levels, selective HSL ranges, and color-grading
wheels during final image conversion. `TuneEditorState` now exposes setter
methods that custom pro controls can call for curves, levels, HSL, and color
grading; a first-party visual curves graph and wheel UI remains a dedicated UI
design slice.

Step 4 adds non-destructive retouch operation primitives and export rendering
for clone stamp, healing brush, and object-removal fills. Retouch operations
reuse `LayerMask`, are stored in state history/import/export, can be added or
removed from `ProImageEditorState`, and are applied during final image
conversion. The object-removal renderer is a deterministic surrounding-pixel
fill, not a bundled generative/content-aware model provider.

AI workflows are represented by examples and integration hooks rather than a
bundled model provider. Catalog management, batch processing, professional
retouching, mask UI/refinement, nonlinear color renderers, RAW processing,
HDR merge, focus stacking, and panorama stitching should be treated as product
epics rather than small editor toggles.

## Implementation Order

1. Harden existing modules until every Current and Partial feature has passing
   QA checks and export parity tests.
2. Add masking and selection primitives, because they unlock retouching,
   adjustment layers, AI correction, and selective effects.
3. Add curves/levels and deeper HSL/color grading on top of the existing tune
   and filter pipeline.
4. Add clone/heal/object-removal workflows, using the same mask and preview
   infrastructure.
5. Add workflow systems: export presets, batch editing, metadata preservation,
   autosave, and recovery.
6. Add pro photography workflows: HDR merge, focus stacking, panorama stitching,
   and RAW/tethered integrations.
