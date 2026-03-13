---
description: Flutter/Dart 코딩 규칙. Dart 파일을 생성하거나 수정할 때 적용.
globs: "lib/**/*.dart"
---

# Flutter/Dart Coding Rules

## CRITICAL

- **DO NOT** hardcode API keys, tokens, or passwords. Use environment variables.
- **DO NOT** use `dynamic` type unless absolutely necessary.
- **DO NOT** use `!` (null assertion) without guaranteed non-null context — prefer `??`, `?.`, or null checks.
- **DO NOT** perform heavy computation or I/O inside `build()` methods.
- **DO NOT** call HTTP/DB directly from UI widgets.

## HIGH

- **DO** use `snake_case.dart` filenames, `PascalCase` classes/enums, `camelCase` variables/functions.
- **DO** prefer `final` and `const` wherever possible.
- **DO** use explicit type declarations — avoid `var` for non-obvious types.
- **DO** follow Effective Dart and null-safety conventions.
- **DO** decompose widgets: no single widget file should exceed ~200 lines.
- **DO** use `ListView.builder` (or similar lazy builders) for long/dynamic lists.
- **DO** handle all UI states: loading, error, empty, data.

## NORMAL

- **DO** use `ChangeNotifier` + `Provider` for state management (project standard).
- **DO** keep business logic in ChangeNotifier/Repository, not in widget code.
- **DO** follow UI → Repository → DataSource layering.
- **DO** wrap AI-generated JSON parsing in `try-catch` with safe conversions (`int.tryParse`, etc.).
- **DO** place mock/dummy data in `lib/data/mock/` or `lib/data/sources/local/`, not in UI code.
