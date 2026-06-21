# wtako-aur-audit

AUR package security auditing for yay, powered by the [aur-audit.wtako.net](https://aur-audit.wtako.net) API. 

See the frontend at https://wtako.net/services/aur-audit

## Features

- **Real-time scanning** - Check AUR packages against known security risks
- **Severity filtering** - Three-tier warning system:
  - ☠️ **Black** - Dangerous operations (root access, disabled security)
  - 🔴 **Red** - High-risk patterns (network downloads, code execution)
  - 🟡 **Yellow** - Moderate concerns (network downloads in PKGBUILD)
- **Auto-exclusion** - Flagged packages are automatically excluded from upgrades based on configured threshold
- **Install blocking** - Prevent installation of dangerous packages

## Installation

```bash
wget https://raw.githubusercontent.com/rxi/json.lua/refs/heads/master/json.lua -P ~/.config/yay/
wget https://raw.githubusercontent.com/Saren-Arterius/wtako-aur-audit/refs/heads/main/init.lua -P ~/.config/yay/
```

## Configuration

Edit `~/.config/yay/config.json` and set `aur_audit_filter`:

```json
{
  "aur_audit_filter": "black"
}
```

Available levels (default: `black`):
- `black` - Exclude packages with ☠️ black flags; all warnings shown
- `red` - Exclude black + 🔴 red flags; all warnings shown
- `yellow` - Exclude black + red + 🟡 yellow flags; all warnings shown
- `none` - Show all warnings, exclude nothing

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

Uses the public [WTAKO AUR Audit API](https://aur-audit.wtako.net) for threat detection. No cache or local database required - all analysis happens server-side. Refer to https://github.com/Saren-Arterius/wtako-aur-audit/blob/main/API.md for API documentation.

The server's source code is purposefully made unavailable.

## License

MIT
