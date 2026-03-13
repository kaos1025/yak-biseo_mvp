---
description: 약비서 UI/UX 규칙. UI 위젯이나 화면을 수정할 때 적용.
globs: "lib/screens/**/*.dart,lib/presentation/**/*.dart,lib/widgets/**/*.dart"
---

# UI/UX Rules (약비서 전용)

## HIGH

- **DO** design for 4050 세대 — use sufficiently large text sizes and high contrast ratios.
- **DO** write all UI-facing text in Korean by default.
- **DO** use `Theme.of(context)` for colors, text styles, and spacing.

## NORMAL

- **DO** use Green for positive indicators, Amber/Orange for warnings.
- **DO** handle loading, error, and empty states in every screen/widget.
- **DON'T** use small or low-contrast text that 4050 users may struggle to read.
