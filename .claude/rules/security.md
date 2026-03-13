---
description: 보안 규칙. 모든 코드 변경 시 적용.
globs: "lib/**/*.dart"
---

# Security Rules

## CRITICAL

- **DO NOT** hardcode API keys, tokens, passwords, or secrets in source code.
- **DO NOT** print or share `.env` file contents.
- **DO NOT** stage `.env`, `.secret`, or `credentials` files for git commit.
- **DO** use environment variables or secure storage for all sensitive data.
- **DO** wrap external API responses in `try-catch` with safe fallback values.
