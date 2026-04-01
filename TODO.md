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

