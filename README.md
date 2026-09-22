# SAT — Silent Authenticator Tool

[![GitHub stars](https://img.shields.io/github/stars/Silent-Protocol-Inc/Silent-Authenticator?style=flat-square)](https://github.com/Silent-Protocol-Inc/Silent-Authenticator/stargazers)
[![GitHub release](https://img.shields.io/github/v/release/Silent-Protocol-Inc/Silent-Authenticator?display_name=tag&style=flat-square)](https://github.com/Silent-Protocol-Inc/Silent-Authenticator/releases)
[![Verify SAT](https://github.com/Silent-Protocol-Inc/Silent-Authenticator/actions/workflows/ci.yml/badge.svg)](https://github.com/Silent-Protocol-Inc/Silent-Authenticator/actions/workflows/ci.yml)
[![GitHub last commit](https://img.shields.io/github/last-commit/Silent-Protocol-Inc/Silent-Authenticator?style=flat-square)](https://github.com/Silent-Protocol-Inc/Silent-Authenticator/commits/main)
[![GitHub top language](https://img.shields.io/github/languages/top/Silent-Protocol-Inc/Silent-Authenticator?style=flat-square)](https://github.com/Silent-Protocol-Inc/Silent-Authenticator)
[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg?style=flat-square)](LICENSE)

SAT is a local-first TOTP manager with an encrypted OpenSSL vault, a Bash CLI, and an optional Python web interface. Version 1.4.0 keeps the legacy `otp.vault` encryption format while separating vault policy, CLI commands, HTTP transport, and browser assets.

## Project Structure

- `sat.sh` is the command entry point; `lib/` contains the CLI, vault policy, and TOTP helper.
- `web/` contains the local HTTP transport and browser assets.
- `tests/` contains disposable unit, integration, load, and browser-contract checks.
- `docs/` and `decisions/` record operating, security, design, and architecture contracts.

## Requirements

Install Bash, OpenSSL, jq, Python 3, `flock`, zip, unzip, and PM2 for background Web UI operation. QR scanning additionally uses `zbarimg`; clipboard support is optional.

Install the maintained launcher with `install -m 700 bin/sat /usr/local/bin/sat` to make this repository available as the global `sat` command. It delegates to `/home/Erpan/SAT/sat.sh`; `wantod/sat.sh` remains a legacy rollback reference.

```bash
chmod +x sat.sh
./sat.sh doctor
./sat.sh init
./sat.sh add github-main
./sat.sh code github-main --clip
./sat.sh list
```

Secrets are prompted without terminal echo. For automation, provide the master password through an inherited descriptor:

```bash
SAT_MASTER_PASS_FD=3 ./sat.sh list --json 3<<<'development-only-password'
```

Use a disposable runtime while testing:

```bash
SAT_HOME=/tmp/sat-dev ./sat.sh init
```

## Backup and Restore

`./sat.sh backup my-vault` creates and verifies an encrypted ZIP without deleting the local vault. `portable` is a safe alias for `backup`. Use `./sat.sh move my-vault` only when the verified backup should be followed by local vault deletion. Restore with `./sat.sh restore my-vault.zip --yes`.

## Web UI

```bash
./sat.sh web-start --host 127.0.0.1 --port 8787
./sat.sh web-status
./sat.sh web-stop
```

`web-start` meminta master password melalui prompt lokal dan baru berhasil setelah endpoint `/health` siap. Untuk mode background, SAT menjalankan server melalui PM2, menyimpan daftar proses PM2, dan pada penggunaan pertama memasang unit systemd PM2 agar proses dipulihkan setelah reboot. Buka URL yang dicetak oleh `web-start` atau `web-status`. Jika port sedang dipakai, pilih port lain, misalnya `./sat.sh web-start --port 8788`. Gunakan `./sat.sh web` hanya bila server perlu tetap berjalan di foreground.

Karena PM2 harus dapat memulai ulang SAT tanpa prompt setelah reboot, mode background menyimpan bundle restart terenkripsi di `$SAT_HOME/sat-web-restart.enc` dan kunci file-mode `0600` terpisah di `$SAT_HOME/sat-web-restart.key`. Keduanya tidak pernah dimasukkan ke argv, environment PM2, URL, atau log, dan akan dihapus oleh `web-stop`. Perlindungan ini membatasi akses ke pengguna sistem yang sama dan bukan pengganti perlindungan terhadap kompromi akun atau root.

For the previous direct-from-VPS workflow, run `sat web-public`. It asks for the master password and a separate Web UI token, binds to the network, and prints the detected VPS URL. Enter that token in the browser access gate. The token stays out of argv, URLs, logs, environment values, and browser storage.

Untuk domain atau subdomain, pilih `Website` lalu `Domain / subdomain HTTPS` dari menu. SAT meminta domain, port origin localhost, mode Cloudflare, token API DNS, dan email Certbot. Alternatifnya, gunakan CLI berikut:

```bash
./sat.sh web-domain sat.example.com --cloudflare dns-only
./sat.sh web-domain sat.example.com --cloudflare proxied
```

Mode domain menggunakan Certbot `dns-cloudflare` untuk membuat dan memvalidasi record TXT ACME, lalu membuat vhost nginx HTTPS yang meneruskan trafik ke SAT di `127.0.0.1:<port>`. Tidak ada port SAT yang dibuka langsung ke internet. `dns-only` berarti grey cloud; `proxied` berarti orange cloud dan memerlukan konfirmasi bahwa Cloudflare berada dalam trust boundary. Buat token API Cloudflare yang dibatasi pada zone terkait: `Zone > Zone > Read` dan `Zone > DNS > Edit`. Token disimpan di `$SAT_HOME/cloudflare.ini` dengan mode `0600` agar renewal Certbot tetap dapat berjalan.

Setiap vhost SAT mengikat tepat **satu hostname** (`server_name <hostname>;`), bukan wildcard dan bukan `default_server`, lalu menulis marker `# SAT owner: <id>` yang diturunkan dari `SAT_HOME` (identitas deployment). Server SAT juga memvalidasi header `Host` pada mode domain sebagai defense-in-depth. Binding bersifat idempotent hanya untuk instance SAT yang sama (SAT_HOME yang sama). Jika hostname sudah di-provision oleh instance SAT lain, SAT menolak dengan `domain_owner_conflict` (exit 5) dan **tidak** menimpa binding lama — hostname milik website lain tidak akan pernah ikut ter-bind atau direbut. Normalisasi input: hostname di-lowercase; input yang bukan hostname valid (misalnya `https://…` atau trailing slash) ditolak oleh validasi.

Kontrak error khusus mode domain:

| Machine code | Exit | Arti / tindakan |
| --- | ---: | --- |
| `domain_host_conflict` | 2 | Jangan gabungkan `--domain` dengan `--host`; SAT memilih loopback untuk mode domain. |
| `invalid_domain` | 6 | Gunakan hostname DNS penuh seperti `sat.example.com`. |
| `cloudflare_dns_required` | 6 | Pilih `dns-only` atau `proxied`; validasi TXT SAT memakai Cloudflare DNS. |
| `web_port_in_use` | 8 | Pilih port origin localhost yang belum dipakai sebelum Certbot dijalankan. |
| `origin_proxy_conflict` | 5 | Port origin sudah diproksikan oleh vhost lain. Lepaskan vhost tersebut atau gunakan port origin lain; SAT tidak berbagi upstream dengan hostname lain. |
| `domain_owner_conflict` | 5 | Hostname sudah diikat oleh instance SAT lain; hentikan instance tersebut sebelum mengikat ulang, binding lama tidak ditimpa. |

Localhost can run without a web token, tetapi mode domain tetap mewajibkan token karena nginx meneruskannya ke Web UI. Token UI berada di memori proses/tab; token Cloudflare hanya dipakai Certbot dan disimpan dalam file mode `0600` untuk renewal. Setel Cloudflare ke `Full (strict)` setelah penerbitan sertifikat. Cloudflare proxy dapat melihat konten Web UI setelah TLS diterminasi di edge; gunakan `dns-only` bila Cloudflare tidak berada dalam trust boundary.

## Terminal language and setup

The interactive `./sat.sh menu` asks users to choose English or Bahasa Indonesia before opening the main menu, then stores only that harmless preference in `$SAT_HOME/config` (mode `0600`). Choose **Language/Bahasa** from the main menu to change it. `SAT_LANG=en` or `SAT_LANG=id` remains an explicit, non-interactive override for scripts.

The HTTPS domain wizard groups Address, DNS, Web UI Security, Cloudflare, and TLS questions. It validates the domain and origin port before continuing, keeps secret input hidden, requires an explicit `yes` for proxied Cloudflare trust, and presents a secret-free configuration summary before Certbot or Nginx changes are applied.

## Web UI Preview

The screenshots below were captured with Google Chrome against a disposable vault containing synthetic `.invalid` accounts. No production vault or OTP material is shown.

| Desktop | Tablet | Mobile |
| --- | --- | --- |
| ![SAT Web UI desktop vault overview](docs/screenshots/2.1.0/desktop-overview.png) | ![SAT Web UI tablet vault overview](docs/screenshots/2.1.0/tablet-overview.png) | ![SAT Web UI mobile vault overview](docs/screenshots/2.1.0/mobile-overview.png) |

## Verification

```bash
bash -n sat.sh lib/*.sh
shellcheck -x sat.sh
python3 -m py_compile lib/totp.py web/server.py
python3 tests/test_server.py
./tests/integration.sh
./tests/load_400.sh
python3 tests/test_totp.py
python3 tests/verify_design.py
```

See [docs/SECURITY.md](docs/SECURITY.md), [docs/DESIGN.md](docs/DESIGN.md), and [docs/MIGRATION_V2.md](docs/MIGRATION_V2.md) for the operating contracts and known limitations.

## Versioning and Releases

SAT follows Semantic Versioning (`MAJOR.MINOR.PATCH`): PATCH releases fix compatible defects, MINOR releases add compatible functionality, and MAJOR releases contain intentional breaking changes. The canonical version is [VERSION](VERSION); release history is maintained in [CHANGELOG.md](CHANGELOG.md).

Before releasing, run the verification commands above, keep `main` clean, create an annotated `vX.Y.Z` tag, then publish the commit and tag. See [CONTRIBUTING.md](CONTRIBUTING.md) for the contributor and release workflow.

## License

Copyright 2026 Silent Protocol Inc. Licensed under the [Apache License 2.0](LICENSE).
