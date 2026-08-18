# yazi Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnubash&logoColor=white)](install-yazi.sh)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black)

Automatisches Installationsskript für den [yazi](https://github.com/sxyazi/yazi)-Terminal-Dateimanager auf Linux. Das Skript lädt die neueste yazi-Version herunter, installiert die Binärdateien in `$HOME/.local/bin` und richtet optional einen Shell-Wrapper ein, der beim Beenden das Verzeichnis wechselt.

[English version](README.md)

## Inhaltsverzeichnis

- [Anforderungen](#anforderungen)
- [Installation](#installation)
- [Verwendung](#verwendung)
- [Shell-Integration](#shell-integration)
- [Aktualisierung](#aktualisierung)
- [Unterstützte Architekturen](#unterstützte-architekturen)
- [Fehlerbehandlung](#fehlerbehandlung)
- [Deinstallation](#deinstallation)
- [Mitwirkende](#mitwirkende)
- [Lizenz](#lizenz)

## Anforderungen

Das Skript setzt folgende Programme voraus:

- `curl` — zum Herunterladen der Release-Dateien
- `unzip` — zum Entpacken des heruntergeladenen Archivs
- Linux-Kernel (macOS, Windows und andere Betriebssysteme werden nicht unterstützt)

Das Skript prüft `curl` und `unzip` automatisch und bricht mit einer aussagekräftigen Fehlermeldung ab, falls eines dieser Programme fehlt.

## Installation

Das Skript wird direkt ausgeführt:

```bash
bash install-yazi.sh
```

Das Skript funktioniert ohne Root-Rechte und speichert alle Dateien in `$HOME/.local/bin`. Nach einer erfolgreichen Installation stehen die Befehle `yazi` und `ya` zur Verfügung.

Wenn die Shell-Integration erfolgreich war, muss eine neue Shell-Sitzung gestartet oder die Konfigurationsdatei (`.bashrc` oder `.zshrc`) neu geladen werden, damit die Änderungen wirksam werden.

## Verwendung

Nach der Installation kann yazi auf zwei Arten gestartet werden:

- `yazi` — öffnet den yazi-Dateimanager direkt
- `y` — öffnet yazi mit automatischem Verzeichniswechsel beim Beenden (siehe Abschnitt Shell-Integration)

Die Binärdateien `yazi` und `ya` befinden sich in `$HOME/.local/bin` und werden automatisch zur `PATH` hinzugefügt (sofern die Shell-Integration erfolgreich war).

## Shell-Integration

Das Skript richtet einen Shell-Wrapper `y()` ein, der yazi startet und beim Beenden automatisch in das Verzeichnis wechselt, das yazi zuletzt angezeigt hat. Dies ist der Hauptvorteil dieses Installers gegenüber einer manuellen Installation.

### Bash und Zsh

Für Bash und Zsh findet die Integration automatisch statt:

1. Eine `y()`-Funktion wird in `$HOME/.bashrc` (für Bash) oder `$HOME/.zshrc` (für Zsh) hinzugefügt.
2. Die `PATH`-Variable wird um `$HOME/.local/bin` erweitert.
3. Falls die Einträge bereits vorhanden sind, werden sie nicht dupliziert.

### Andere Shells (Fish, Dash, Csh, etc.)

Für andere Shells kann das Skript die Integration nicht automatisch durchführen. Stattdessen zeigt es eine Warnung mit den erforderlichen Zeilen:

```
export PATH="$HOME/.local/bin:$PATH"

function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
    command rm -f -- "$tmp"
}
```

Diese Zeilen müssen manuell in die Shell-Konfigurationsdatei eingefügt werden. Die genaue Datei hängt von der Shell ab (z. B. `~/.config/fish/config.fish` für Fish).

## Aktualisierung

Nach der Installation wird ein Skript `$HOME/.local/bin/update-yazi` bereitgestellt, das später zum Durchführen eines Updates verwendet werden kann:

```bash
update-yazi
```

Das Update-Skript führt die gleiche Architektur- und libc-Erkennung wie das ursprüngliche Installationsskript durch und lädt die neueste yazi-Version herunter und installiert diese.

## Unterstützte Architekturen

Das Skript unterstützt alle Architekturen, für die yazi Release-Dateien bereitstellt:

- `x86_64` — mit automatischer glibc/musl-Erkennung
- `aarch64` (ARM64) — mit automatischer glibc/musl-Erkennung
- `i686` — nur glibc
- `riscv64gc` — nur glibc
- `sparc64` — nur glibc

Falls die Systemarchitektur nicht unterstützt wird, zeigt das Skript eine aussagekräftige Fehlermeldung an und beendet sich, ohne Änderungen vorzunehmen.

### LibC-Erkennung

Das Skript erkennt automatisch, ob das System glibc oder musl als C-Bibliothek nutzt. musl-Versionen von yazi sind für `x86_64` und `aarch64` verfügbar; für alle anderen Architekturen wird automatisch die glibc-Variante verwendet.

## Fehlerbehandlung

Das Skript überprüft alle Voraussetzungen vor der Ausführung:

- Linux-Kernel
- Verfügbarkeit von `curl` und `unzip`
- Unterstützte CPU-Architektur
- Erfolgreiches Herunterladen und Entpacken des yazi-Archivs

Falls einer dieser Schritte fehlschlägt, zeigt das Skript eine aussagekräftige Fehlermeldung an und beendet sich mit Exit-Code 1, ohne das System zu ändern.

## Deinstallation

Das Skript `uninstall-yazi.sh` wird ausgeführt, um die installierten Binärdateien (`yazi`, `ya`, `update-yazi`) aus `$HOME/.local/bin` zu entfernen und den `y()`-Wrapper sowie die `PATH`-Zeile aus `.bashrc`/`.zshrc` zu löschen:

```bash
bash uninstall-yazi.sh
```

## Mitwirkende

Dieser Installer ist ein Skript eines Drittanbieters und ist nicht mit dem yazi-Projekt verbunden oder von diesem bestätigt. Alle Anerkennung für yazi selbst geht an [sxyazi](https://github.com/sxyazi) und die [yazi-Mitwirkenden](https://github.com/sxyazi/yazi/graphs/contributors). Das für den Verzeichniswechsel beim Beenden verwendete `y()`-Shell-Wrapper-Muster folgt dem in [yazis eigenem Quick-Start-Leitfaden](https://yazi-rs.github.io/docs/quick-start) dokumentierten Ansatz.

## Lizenz

Dieses Installer-Skript wird unter der [MIT-Lizenz](LICENSE) veröffentlicht. yazi selbst wird unter seiner eigenen Lizenz vertrieben – siehe das [yazi-Repository](https://github.com/sxyazi/yazi) für Details.
