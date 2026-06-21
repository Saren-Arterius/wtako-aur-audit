# wtako-aur-audit

AUR package security auditing for yay, powered by the [aur-audit.wtako.net](https://aur-audit.wtako.net) API. See a frontend at https://wtako.net/services/aur-audit

## Features

- **Real-time scanning** - Check AUR packages against known security risks
- **Severity filtering** - Three-tier warning system:
  - ☠️ **Black** - Dangerous operations (root access, disabled security)
  - 🔴 **Red** - High-risk patterns (network downloads, code execution)
  - 🟡 **Yellow** - Moderate concerns (network downloads in PKGBUILD)
- **Auto-exclusion** - Flagged packages are automatically excluded from upgrades based on configured threshold
- **Install blocking** - Prevent installation of dangerous packages

## Installation

2. Copy this `init.lua` to `~/.config/yay/init.lua`

## Configuration

Set the audit filter level via environment variable or yay config:

```bash
export YAY_OPTS="--aur-audit-filter=black"
```

Available levels:
- `black` - Only block packages with dangerous flags (default)
- `red` - Block high-risk packages
- `yellow` - Filter moderately suspicious packages
- `none` - Disable filtering (warnings only)

## Usage

The integration works transparently - just use yay normally:

- **Search**: Flagged packages are filtered out based on your level setting
- **Upgrade**: Potentially risky packages are excluded from bulk upgrades
- **Install**: Blocked packages are rejected with an error message

## Example Output

```
==> 要安裝的套件包 (例如: 1 2 3, 1-3 或 ^4)
==> 1
========== ⚠️  AUR AUDIT by wtako.net ⚠️  ==========
🟡 some-package: Network download (curl/wget) detected in PKGBUILD
❓ another-package: Scanning in progress
==================================================
```

## API Documentation

Uses the public [wtako AUR Audit API](https://aur-audit.wtako.net) for threat detection. No cache or local database required - all analysis happens server-side.

## License

MIT
