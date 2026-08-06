# Ubuntu and Debian guide

## Supported setup

The scripts support x86_64 Ubuntu, Debian, and distributions that identify with
the Debian family in `/etc/os-release`.

The common application route is:

- Steam: an existing native install is used first, otherwise the script offers
  the Flathub build.
- Lutris: Flathub.
- XIVLauncher: XLM for Steam integration or Flathub for standalone desktop use.
- GE-Proton: the verified upstream archive installed for the detected Steam.

## First run

```bash
./install.sh prerequisites --with-steam
./install.sh doctor
```

If `flatpak` or the download verification tools are absent, the script runs:

```text
sudo apt-get update
sudo apt-get install ...
```

That is the only time the base operating system is changed. Game launchers and
compatibility tools remain scoped to the current user.

## Native Steam versus Flatpak Steam

The installer prefers an existing native Steam installation. Force a particular
target only when you know which Steam you use:

```bash
./install.sh proton --steam-mode native
./install.sh proton --steam-mode flatpak
./install.sh ffxiv --method steam --steam-mode flatpak
```

Do not maintain the same game prefix from both native and Flatpak Steam. Their
home and compatibility-tool paths differ.

## NVIDIA and Vulkan

Battle.net is a 32-bit launcher even when WoW is 64-bit. A working Linux gaming
stack therefore needs both 64-bit and 32-bit Vulkan libraries. Install NVIDIA
drivers from your distribution's supported repository, not a standalone `.run`
file. AMD and Intel users should use the Mesa packages supplied for their
distribution release unless a documented hardware issue requires otherwise.

Run:

```bash
./install.sh doctor
```

The doctor can confirm that a Vulkan ICD exists and, when `vulkaninfo` is
installed, that Vulkan initializes. It cannot confirm every 32-bit driver path
inside every launcher sandbox.

## AppArmor note for native Lutris

Recent Ubuntu releases have had UMU/AppArmor integration problems with some
native Lutris packages. This project uses the Lutris Flatpak to keep the
cross-distribution path consistent. Do not mix a native Lutris prefix and the
Flatpak Lutris prefix unless you deliberately migrate it.

