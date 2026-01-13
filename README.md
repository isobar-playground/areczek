# areczek — OpenCode pack

Globalny “pack” dla OpenCode (agent `areczek` + subagenty + własne toole) instalowany jednym poleceniem i uruchamiany przez wrapper `opencode-areczek`.

## Szybki start (użytkownik)

### Wymagania

- macOS albo Windows z WSL
- `bash`, `curl`, `tar`

### Instalacja (latest)

To polecenie:
- zainstaluje OpenCode (jeśli nie masz `opencode` w PATH)
- zainstaluje/zaaktualizuje pack do `~/.config/opencode-packs/areczek`
- zainstaluje wrapper `~/.local/bin/opencode-areczek`

```bash
curl -fsSL https://raw.githubusercontent.com/isobar-playground/areczek/master/install.sh | bash
```

### Uruchomienie

```bash
opencode-areczek
```

Wrapper ustawia `OPENCODE_CONFIG_DIR=~/.config/opencode-packs/areczek` i odpala `opencode --agent areczek`.

Możesz też przekazać argumenty bezpośrednio do OpenCode, np.:

```bash
opencode-areczek --continue
opencode-areczek run "Wyjaśnij jak działa ten projekt"
```

### PATH na macOS

Jeśli po instalacji `opencode-areczek` nie jest dostępny, dodaj do `~/.zshrc` (lub `~/.bashrc`):

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Co jest w paczce

- Agenci: `agent/areczek.md`
- Subagenci: `agent/subagents/*.md`
- Plugin z toolami: `plugin/areczek-tools.ts`
  - `areczek_echo` — echo message (sanity check)
  - `areczek_now` — aktualny timestamp ISO

## Jak dodawać własne rzeczy (maintainer)

### Agent / subagent

- Primary agent: dodaj plik `agent/<nazwa>.md` z frontmatter (`mode: primary`).
- Subagent: dodaj plik `agent/subagents/<nazwa>.md` z frontmatter (`mode: subagent`).

Nazwa pliku staje się nazwą agenta.

### Toole

W tym szablonie toole są dostarczane przez plugin w `plugin/areczek-tools.ts`.

Jeśli chcesz dodać nowe narzędzie, dopisz je w mapie `tool: { ... }` w tym pliku.

## Aktualizacja / reinstalacja

Instalator jest idempotentny — uruchom ponownie to samo polecenie:

```bash
curl -fsSL https://raw.githubusercontent.com/isobar-playground/areczek/master/install.sh | bash
```

Jeśli pack już istnieje, instalator robi backup katalogu:

- `~/.config/opencode-packs/areczek.bak.<timestamp>`

## Uninstall

Usuń wrapper:

- `~/.local/bin/opencode-areczek`

Usuń pack:

- `~/.config/opencode-packs/areczek`
- opcjonalnie backupy `~/.config/opencode-packs/areczek.bak.*`

OpenCode usuwa się osobno (zależnie od metody instalacji).

## Release (GitHub Actions)

Repo ma workflow `.github/workflows/release.yml`.

### Release przez tag

1. Zwiększ wersję (według własnych zasad).
2. Utwórz tag i wypchnij go na origin:

```bash
git tag v0.1.0
git push origin v0.1.0
```

3. Workflow utworzy GitHub Release z wygenerowanymi notatkami.

### Release manualny

W GitHub → Actions → `Release` → `Run workflow`:
- podaj `tag` (np. `v0.1.0`)
- opcjonalnie ustaw `prerelease=true`

Workflow utworzy tag (jeśli nie istnieje), wypchnie go i zrobi release.
