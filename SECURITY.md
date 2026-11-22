# Security Policy

## Supported Versions

Scatter Notes is currently in active initial development on the `main` branch. Security fixes are applied directly to `main`.

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, report vulnerabilities privately using **GitHub Private Vulnerability Reporting** (under the repository's **Security** tab -> **Advisories** -> **Report a vulnerability**).

When reporting, please include:
- A clear description of the vulnerability and potential impact
- Steps to reproduce or a minimal proof of concept
- Affected platform/component (e.g., local database, markdown/block parser, Android intent handling)

You can expect an acknowledgment within 72 hours and regular updates until a fix is verified and released.

## Security & Secret Hygiene Standards

- **Zero Secrets in Git**: Never commit `.env` files, API tokens, Android signing keystores (`*.jks`, `*.keystore`), `key.properties`, or Firebase config files.
- **Automated Protections**: This repository uses GitHub **Secret Scanning**, **Push Protection**, and **Dependabot** alerts/security updates.
- **Local-First Data Privacy**: User notes are stored locally on-device by default. Any future sync or export features must prioritize explicit user consent and encryption in transit and at rest.
- **Release Signing**: Production Android builds must use CI secrets stored inside a protected GitHub Environment with required reviewers—never local unencrypted keys checked into the repository.
