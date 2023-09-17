# GitHub Backup Script

This script provides a way to backup all the repositories of a GitHub user to a local machine.

## Prerequisites

- `jq`: A lightweight and flexible command-line JSON processor. If you don't have it installed, you can typically do so via a package manager:
  - On Debian/Ubuntu: `sudo apt install jq`
  - On macOS with Homebrew: `brew install jq`

- **GitHub Personal Access Token**: This script requires a GitHub personal access token with the appropriate permissions (e.g., `repo` for private repositories). You can generate a personal access token by following these steps:
  1. Go to [GitHub's settings](https://github.com/settings/profile).
  2. On the left sidebar, click on "Developer settings."
  3. Go to "Personal access tokens" and click "Generate new token."
  4. Give your token a name, set the necessary permissions, and generate the token.
  5. **Important**: Copy your new access token and save it somewhere secure. Once you leave the page, you won't be able to see it again.

## Usage

1. Clone/download this repository.
2. Navigate to the directory containing the script.
3. Ensure the script (`backup_script.sh` or whatever you've named it) has execute permissions: `chmod +x backup_script.sh`
4. Run the script: `./backup_script.sh`
5. When prompted, enter your GitHub personal access token.
6. The script will then begin cloning all repositories associated with the user linked to the token.

## Warning

This script will overwrite local repositories if they share the same name as the repositories on GitHub. Make sure you have no important unsaved changes in any local repos with matching names before running the script.
