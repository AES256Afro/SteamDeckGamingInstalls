# Troubleshooting

Start with:

```bash
./install.sh doctor
```

Keep the newest log from:

```text
~/.local/state/steam-deck-gaming-installs/
```

Do not post logs until you have checked them for your Linux username, paths, or
other personal information. The scripts never request game passwords.

## GE-Proton does not appear in Steam

1. Fully exit Steam, not just the visible window.
2. Start Steam again.
3. Open one game's **Properties > Compatibility** list.
4. Run `./install.sh doctor` and confirm it finds GE-Proton in the same Steam
   installation you launched.
5. If both native and Flatpak Steam exist, specify the correct target:

   ```bash
   ./install.sh proton --steam-mode native
   ./install.sh proton --steam-mode flatpak
   ```

Do not copy the same extracted directory back and forth while Steam is running.

## XLM / XLCore does not appear

1. Run `./install.sh ffxiv --method steam` again.
2. Confirm the script detected the Steam installation you actually use.
3. Fully restart Steam.
4. Look for **XLCore [XLM]**, not GE-Proton, in the FFXIV Compatibility list.
5. Clear the FFXIV **Launch Options** field.

For Flatpak Steam, XLM data is inside the Flatpak Steam home. Do not move
`~/.xlcore` between native and Flatpak layouts without following the current XLM
migration guidance.

## XIVLauncher reports no secrets provider

The Steam Deck and Flatpak XLM paths enable the upstream fallback provider. On a
native desktop, make sure a supported keyring such as KDE Wallet or GNOME
Keyring is installed and unlocked. Use the fallback only after reading the
current XLM/XIVLauncher guidance because it changes how saved credentials are
protected.

## Battle.net installer stops at the login window

During the first scripted installation, the maintained Lutris installer expects
you to close the Battle.net login window without signing in. Lutris then
completes the prefix configuration. Launch Battle.net from the Lutris library
after completion and sign in on that second launch.

## Battle.net is slow or does not start

Check one variable at a time:

1. Confirm the prefix is not on NTFS.
2. Confirm Vulkan works with `./install.sh doctor`.
3. Update Lutris and runners with `./install.sh update`.
4. In Lutris, test the existing runner before changing it.
5. If using **GE-Proton (Latest)**, enable Lutris debug logging and capture the
   UMU error before switching runners.
6. Check whether a DNS filter or proxy blocks `blizzard.com` or `battle.net`
   downloads. Lutris documents that filtering can stall the agent installer.

Do not delete the entire prefix as a first troubleshooting step. Battle.net can
scan for existing game files, but deleting the prefix also discards launcher
configuration and may require a full repair.

## microSD path is missing

1. Return to Desktop Mode.
2. Open Dolphin and mount the card.
3. Check the path under `/run/media/deck`.
4. If the mount name changed, restore the previous name or update the Lutris
   game configuration to the new absolute path.
5. Reapply the targeted permission if needed:

   ```bash
   flatpak override --user --filesystem=/run/media/deck/CARD/Games net.lutris.Lutris
   ```

## Create a focused log

Lutris can be started from a terminal with debug output:

```bash
flatpak run net.lutris.Lutris -d
```

Valve Proton logging for a Steam game uses this launch option:

```text
PROTON_LOG=1 %command%
```

Remove it when troubleshooting is complete because logs can grow and include
local paths. XLM and Lutris/UMU have their own logs, so a Valve Proton log is not
the right evidence for every launcher path.

