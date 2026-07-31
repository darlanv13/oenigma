1. **Fix `admin_events_screen.dart` to display event titles**: Use `replace_with_git_merge_diff` to modify the `title` field in `lib/painel_admin/features/admin/screens/admin_events_screen.dart` to read `event.get<String>('title') ?? event.get<String>('name') ?? 'Sem Nome'`.
2. **Fix `admin_enigmas_screen.dart` to display event names in the dropdown**: Use `replace_with_git_merge_diff` to modify `lib/painel_admin/features/admin/screens/admin_enigmas_screen.dart`, updating the `DropdownMenuItem` text and the `eventName` variable to include `title` fallbacks.
3. **Verify changes**: Run `flutter analyze` using `run_in_bash_session` to verify the codebase and ensure no regressions were introduced.
4. **Complete pre-commit steps to ensure proper testing, verification, review, and reflection are done.**
5. **Submit**. Use `submit`.
