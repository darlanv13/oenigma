1. **Fix `TypeError` when reading and saving `prizePool` in `admin_events_screen.dart`**: Use `replace_with_git_merge_diff` to modify `lib/painel_admin/features/admin/screens/admin_events_screen.dart`. Change the initialization of `prize` and `premioController` to use `.get<dynamic>('field')?.toString()`. Also update the `'prizePool'` assignment in both `createOrUpdateEvent` calls to use `premioController.text.trim()` directly as a string instead of parsing it to a number.
2. **Verify changes**: Run `flutter analyze` using `run_in_bash_session` to verify the codebase and ensure no regressions were introduced.
3. **Complete pre-commit steps to ensure proper testing, verification, review, and reflection are done.**
4. **Submit**. Use `submit`.
