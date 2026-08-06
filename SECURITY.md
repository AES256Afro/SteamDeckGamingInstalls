# Security model

## Download verification

- GE-Proton release metadata comes from the GitHub API over HTTPS.
- The archive must match GitHub's release-asset digest.
- The checksum file must also match its GitHub digest.
- The archive must then pass GE-Proton's published SHA-512 checksum.
- Archive entries are rejected if they are absolute, escape with `..`, contain
  special device nodes, use escaping links, or have more than one top-level
  directory.
- XLM must match the digest in its GitHub release metadata before execution.
- The maintained Lutris installer is requested through Lutris at launch time.

No release version or checksum is copied into the repository, so an update does
not require a code change. The tradeoff is that the GitHub account and current
release remain part of the trust boundary.

## Privilege boundary

Run the project as a regular desktop user. It exits when run as root. On Ubuntu,
Debian, or regular Arch it may request sudo for distribution packages such as
Flatpak or curl. It does not use sudo for launchers, game data, Proton, or XLM.

SteamOS's immutable base is left intact.

## Credentials

The scripts do not ask for, read, or store Battle.net or Square Enix
credentials. Login stays in the upstream graphical launcher. A `GITHUB_TOKEN`
can optionally be supplied to avoid API rate limits; it is passed in an HTTP
header and is never printed by the download helper.

## Reporting a problem

Open a GitHub issue with:

- distribution and version;
- native or Flatpak Steam;
- the command used;
- the failure text;
- a redacted doctor result.

Do not attach unreviewed logs, account identifiers, authentication tokens, or
screenshots that show email addresses.
