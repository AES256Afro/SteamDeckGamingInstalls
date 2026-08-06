# World of Warcraft guide

## What this installs

The workflow uses three maintained layers:

1. Lutris from Flathub provides the graphical launcher manager.
2. Lutris's published `battlenet-standard` installer creates a dedicated 64-bit
   prefix and installs Battle.net.
3. Lutris can run the prefix through `GE-Proton (Latest)`, which uses UMU to
   provide the Steam runtime and current Proton fixes outside Steam.

The script does not collect a Battle.net password, choose a WoW subscription,
or silently download the game. Those actions happen in the official Battle.net
window.

## Before starting

- Use Desktop Mode on Steam Deck.
- Connect power and use a stable network. Battle.net and WoW downloads are large
  and can take long enough for an unplugged handheld to sleep or lose power.
- Make sure the target drive has enough free space for the WoW edition shown by
  Battle.net, plus room for updates and the Battle.net prefix.
- Use ext4 or Btrfs. A microSD card formatted by Steam Deck is normally ext4.
- Do not put the Battle.net prefix on NTFS. Lutris explicitly documents that
  Battle.net does not work correctly there.
- Update SteamOS or your distribution normally before troubleshooting GPU
  drivers. Proton depends on Vulkan and working 32-bit graphics libraries.

## Install to internal storage

Run:

```bash
./install.sh wow
```

When Lutris asks for the install location, use the path printed by the script,
normally:

```text
/home/YOUR-USER/Games/Battle.net
```

The path is the prefix. Battle.net and WoW live inside it.

## Install to a Steam Deck microSD card

1. Format the card from **Steam > Settings > System > Format SD Card** if it is
   not already in a Steam Deck-supported Linux format. Formatting erases the
   card, so copy anything important elsewhere first.
2. Switch to Desktop Mode.
3. Open Dolphin and click the card once so it is mounted.
4. In Konsole, run `ls /run/media/deck` to see the mount name.
5. Run, replacing `YOUR-CARD`:

   ```bash
   ./install.sh wow --library /run/media/deck/YOUR-CARD/Games
   ```

The script creates the directory and grants only that path to the Lutris
Flatpak. It prints the full destination to select in Lutris.

## The Lutris installer sequence

The order matters:

1. Lutris opens an installer page for Battle.net.
2. Confirm the separate Battle.net destination printed by the script.
3. Lutris downloads Blizzard's current Battle.net installer and creates the
   prefix.
4. A Battle.net login window eventually appears during the scripted install.
5. **Do not sign in during this first appearance. Close the window.** This is an
   instruction from the maintained Lutris installer and lets Lutris finish its
   remaining tasks.
6. Wait for Lutris to report that the installation is complete.
7. Select Battle.net in the Lutris library and click **Play**.
8. Sign in now.
9. Select **World of Warcraft** and choose Retail, Classic, or another edition
   offered to your account.
10. Choose the install location inside the existing Battle.net prefix and let
    Battle.net download the game.

## Select GE-Proton through UMU

If Battle.net is working, do not change several runner settings at once. If you
want the current GE-Proton path:

1. Right-click Battle.net in Lutris.
2. Choose **Configure**.
3. Open **Runner options**.
4. Set **Wine version** to **GE-Proton (Latest)** if it is offered.
5. Save and launch Battle.net once.

Current GE-Proton documentation says Lutris uses UMU as its default backend when
that runner is selected. UMU downloads the matching Steam Linux Runtime and
applies shared Proton fixes. The separately installed Steam GE-Proton build is
still useful for Steam games, but Lutris manages its own selected runner path.

## Add it to Steam Gaming Mode

Finish the Battle.net installation and confirm it launches from Lutris first.
Then:

1. In Lutris, right-click Battle.net.
2. Choose **Create Steam shortcut** if the option is available.
3. Fully exit Steam and start it again.
4. Look under **Library > Non-Steam**.

If Flatpak permissions prevent Lutris from writing a shortcut:

1. Open Steam in Desktop Mode.
2. Choose **Games > Add a Non-Steam Game to My Library**.
3. Add Lutris.
4. In Gaming Mode, launch Lutris and then Battle.net.

Direct per-game shortcut creation is intentionally not automated here because
Steam's binary shortcut database can be corrupted if it is edited while Steam
is running.

## Updates

- Battle.net updates itself.
- WoW updates through Battle.net.
- Lutris updates through Flatpak.
- UMU and `GE-Proton (Latest)` update through Lutris's runner behavior.
- Steam GE-Proton updates with `./install.sh update`.

The updater does not delete or rebuild the Battle.net prefix.
