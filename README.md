# Workflows

CI steps shared by **[Arch OS](https://github.com/murkl/arch-os)**, its **[System Manager](https://github.com/murkl/arch-os-manager)**, **[D2Launcher](https://github.com/murkl/d2launcher)** and the **[Plymouth theme](https://github.com/murkl/plymouth-theme-arch-os)**.

## Release Notes

`notes` checks a pushed version tag and writes its notes out of the commit titles since the last release. Each title is a short phrase a user understands, the notes start it with a capital: `feat: the Recovery updates itself` becomes `* The Recovery updates itself` under Features.

```yaml
release:
  name: Release
  if: github.ref_type == 'tag'
  runs-on: ubuntu-24.04
  permissions:
    contents: read
  outputs:
    version: ${{ steps.notes.outputs.version }}
    notes: ${{ steps.notes.outputs.notes }}
  steps:
    - id: notes
      uses: murkl/workflows/notes@<sha> # 1.0.0
```

Before the tag, in the project next to this checkout:

```
../workflows/notes/notes.sh 2.1.0 && git tag 2.1.0 && git push origin 2.1.0
```

| Title | Section |
| --- | --- |
| `feat!:` | ⚠ BREAKING CHANGES |
| `feat:` | Features |
| `fix:` | Bug Fixes |
| `perf:` | Performance Improvements |
| no type | Other Changes |
| `docs:` `ci:` `chore:` and the like | none |

- Refused: no x.y.z, not on `main`, not above the last release, nothing for users
- Tags never move, so a refused tag is never pushed

## Settings

`settings.sh` applies a project's `.github/settings/` to its repository on GitHub, as an admin logged in with `gh`. In the project:

```
../workflows/settings/settings.sh
```

| File | Says |
| --- | --- |
| `repository.json` | Description, merge methods and features |
| `actions.json` | Workflow token permissions |
| `ruleset-*.json` | One ruleset each, found by its name |
| `topics.json` | Topics, optional |
| `code-scanning.json` | Code scanning, optional |

## Banner

`banner.py` renders a project's `docs/banner.png`, also its social preview, out of two screenshots and its `product.yaml`. Needs chromium and imagemagick. In the project:

```
python3 ../workflows/banner/banner.py --tagline "…" --card back.png --card front.png
```

## Development

```
make check    # the gate CI runs
make github   # .github/settings/ applied, as an admin
```

A change of an action is tagged as a version. Dependabot raises it in every project.
