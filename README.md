# areczek — OpenCode pack

Globalny “pack” dla OpenCode (agent `areczek` + subagenty + własne toole) instalowany jednym poleceniem i uruchamiany przez wrapper `areczek`.

## Szybki start (użytkownik)

### Wymagania

- macOS albo Windows z WSL
- `bash`, `curl`, `tar`

### Instalacja (latest)

To polecenie:
- zainstaluje OpenCode (jeśli nie masz `opencode` w PATH)
- zainstaluje/zaaktualizuje pack do `~/.config/opencode-packs/areczek`
- zainstaluje wrapper `~/.local/bin/areczek`

```bash
curl -fsSL https://github.com/isobar-playground/areczek/releases/latest/download/install.sh | bash
```

### Uruchomienie

```bash
areczek
```

Wrapper ustawia `OPENCODE_CONFIG_DIR=~/.config/opencode-packs/areczek` i odpala `opencode --agent areczek`.

Możesz też przekazać argumenty bezpośrednio do OpenCode, np.:

```bash
areczek --continue
areczek run "Wyjaśnij jak działa ten projekt"
```

### PATH na macOS

Jeśli po instalacji `areczek` nie jest dostępny, dodaj do `~/.zshrc` (lub `~/.bashrc`):

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Co jest w paczce

- Agenci: `agent/areczek.md`
- Subagenci: `agent/subagents/*.md` (m.in. `januszek`, `aireczek`, `anetka`)
- Plugin z toolami: `plugin/areczek-tools.ts`
  - `areczek_jira_summary` — podsumowanie zadania JIRA na podstawie URL

## Przepływ pracy (Areczek + subagenci)

1. Areczek pobiera ticket JIRA (używając `areczek_jira_summary`), zbiera kontekst projektu i uruchamia Januszka.
2. Januszek tworzy PRD dla ticketu (w runtime, nie część packa).
3. Areczek analizuje PRD i strukturę repo, generuje małą feature listę (`feature_list_{TICKET}.json`) i odpala AIreczka.
4. AIreczek realizuje tylko ok. 10–20% zadań (min. jedno), oznacza je jako `passes=true` po testach i proponuje commit.
5. Gdy wszystkie zadania mają `passes=true`, Anetka uruchamia regresję/testy całościowe i raportuje wynik.

## Artefakty runtime (tworzone przy zleceniu, nie w repo packa)

- PRD: `prd_{TICKET}.md`
- Feature lista: `feature_list_{TICKET}.json`
- Runbook startu (gdy brak instrukcji): `runbook_{TICKET}.md`
- Raport testów końcowych: `test-report_{TICKET}.md`

Domyślny katalog roboczy dla tych plików to `./context/` w aktywnym projekcie. Jeśli repo nie powinno ich śledzić, poproś Areczka o dodanie do `.gitignore` lub wskaż inną lokalizację.
Alternatywnie możesz poprosić o lokalne ignorowanie w `.git/info/exclude`, jeśli nie chcesz commitować wzorców.

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
curl -fsSL https://github.com/isobar-playground/areczek/releases/latest/download/install.sh | bash
```

Jeśli pack już istnieje, instalator robi backup katalogu:

- `~/.config/opencode-packs/areczek.bak.<timestamp>`

## Uninstall

Usuń wrapper:

- `~/.local/bin/areczek`

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
