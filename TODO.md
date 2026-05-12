# Pro Image Editor Error Fixing - Approved Plan Steps

## Plan Summary
- Update deps for compatibility
- Fix example/ dep conflict (shared_preferences git vs supabase_flutter)
- Soften ImageExceptions in plugins/image (TIFF/LZW/Fax/JPEG decoders)
- Add guards in crop_rotate_editor, state_manager, utils (double_parser, converters)
- Run fixes/analysis/tests

Status: [ ] Not started | [ ] In progress | [x] Pending verification

## Step-by-Step Tasks

1. **[ ] Update pubspec.yaml**: Switch git deps to hosted (shared_preferences ^2.3.2, plugin_platform_interface ^2.1.8), update flutter_lints ^5.2.0, SDK '>=3.4.0 <4.0.0', flutter '>=3.24.0'. Run `flutter pub get`
2. **[ ] Update example/pubspec.yaml**: Align deps or remove supabase_flutter temporarily to fix conflict
3. **[ ] Fix plugins/image exceptions**: In tiff_lzw_decoder.dart, tiff_fax_decoder.dart, etc. - return null/invalid Image instead of throw ImageException
4. **[ ] Guard crop_rotate_editor.dart**: Implement safe clamp for Android Samsung S10
5. **[ ] Guard main_editor/services/state_manager.dart**: Check history bounds before undo/redo
6. **[ ] Fix utils**: double_parser.dart, converters.dart - add null/edge checks
7. **[ ] Auto-fix lints**: `dart fix --apply`
8. **[ ] Verify**: `flutter analyze .`, `flutter test`, `flutter pub outdated`
9. **[ ] Complete**: All checks pass, update this TODO.md

Next action: Complete step by step.




Todo 

1. **Text overlays**
   Add title/caption stickers like “Happy Birthday”, “Our Wedding”, “Trip 2026”, with font, color, size, rotation, and shadow controls.

2. **Stickers / occasion decorations**
   Hearts, balloons, confetti, stars, rings, graduation caps, festive lights, travel stamps, etc. Especially useful for the “special occasion” themes.

3. **Per-photo editing inside collage**
   Tap a photo to change crop position, zoom, rotate, flip, replace image, or apply a filter only to that photo.

4. **Freestyle layer controls**
   Bring forward, send backward, duplicate, lock position, delete from canvas, rotate photo, snap to center/edges.

5. **More export sizes**
   Square, Instagram story `9:16`, portrait `4:5`, landscape `16:9`, wallpaper, custom size.

6. **Template categories**
   Instead of only “2 photos / 3 photos”, add tabs like `Classic`, `Wedding`, `Birthday`, `Travel`, `Festival`, `Minimal`, `Magazine`.

7. **Borders and frames**
   Photo border color, border width, shadow style, paper/photo-frame look, polaroid style.

8. **Background controls**
   Solid colors, gradients, patterns, blur background from selected image, custom background image.

9. **Auto shuffle**
   One button that randomizes template, photo order, theme, spacing, and radius until the user likes a design.

10. **Save/load draft**
   Store selected layout, theme, image order, freestyle positions, spacing, radius, captions, stickers.
