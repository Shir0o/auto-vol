# Security Policy

## Supported versions

This project is in early development. Security fixes are applied to the `main` branch.

## Reporting a vulnerability

Please do not open a public GitHub issue for suspected vulnerabilities.

To report a security issue, contact the maintainer privately with:

- A concise description of the issue
- Steps to reproduce or proof-of-concept details
- Affected platforms, if known
- Any suggested mitigation

If GitHub private vulnerability reporting is enabled for the repository, use that first. Otherwise, contact the maintainer listed in [CODEOWNERS](.github/CODEOWNERS).

## Handling credentials

Do not commit `.env` files, OAuth client secrets, API keys, tokens, signing keys, or provisioning profiles. Use `.env.example` for placeholder configuration only.
