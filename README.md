# GitHub Backup

GitHub has been banning infosec accounts without warning or explanation. Years of research, tools, and PoCs gone overnight. Don't wait for it to happen to you.

Full mirror backup of your entire GitHub account: repositories (public + private), wikis, and gists (including secret ones). Subsequent runs are incremental.

## Requirements

- [GitHub CLI](https://cli.github.com) (`gh`), authenticated
- `git`

## Usage

```bash
# Default: backs up to ~/github-backup, 4 parallel jobs
./backup_script.sh

# Custom backup directory
./backup_script.sh /mnt/external/github-backup

# Custom directory + 8 parallel jobs
./backup_script.sh /mnt/external/github-backup 8
```

## What gets backed up

| Type | Method | Incremental |
|------|--------|-------------|
| Public repos | `git clone --mirror` | Yes (`git remote update`) |
| Private repos | `git clone --mirror` | Yes |
| Wikis | `git clone --mirror` | Yes |
| Gists (public + secret) | `git clone --mirror` | Yes |

Mirror clones include all branches, tags, and refs.

## Restoring

To restore a mirror clone into a working repository:

```bash
git clone path/to/repo.git restored-repo
```

## License

MIT
