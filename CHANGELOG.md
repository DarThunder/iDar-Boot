# Changelog

All notable changes to the **iDar-Boot** project will be documented in this file.

## Alpha

### v1.0.0

### Added

#### Core Bootloader

- **Master Boot Record (MBR):** Developed the foundational `MBR.lua` to bridge CC:T hardware with the Loom kernel.
- **Hardware Persistence:** Implemented `/etc/hardware.conf` to store and persist computer identifiers and boot metadata.
- **Global Boot API:** Introduced the `_G.iDarBoot` API, allowing sandboxed applications to query hardware information and register services.

---

### v2.0.0

### Added

#### Initialization & Init System (PID 1)

- **Shell Persistence:** The `init.lua` process now monitors the shell session and automatically respawns it after a 1-second delay if it crashes or exits.
- **Service Autostart:** Implemented a standardized service loader that reads `/etc/autostart.conf` and spawns background daemons at boot time.
- **Foreground Focus Management:** The init system now explicitly manages terminal focus, granting it to the shell upon startup via `sys.set_foreground`.

#### TTY & Input Management

- **TTY Daemon:** Introduced a dedicated input multiplexer (`tty_daemon.lua`) to capture raw keyboard events and route them securely to the active foreground process.
- **Input Isolation:** Key events are now prefixed with the target PID (e.g., `fg_char_[pid]`), preventing background processes from intercepting user input.

#### Bootloader & Hardware

- **Dynamic MAC Derivation:** Improved the hardware initialization logic to derive a unique, deterministic MAC address using the computer's ID as a seed.
- **VFS Integration:** Transitioned the configuration loading logic to use Loom's virtual syscalls, ensuring all boot-time file operations are sandboxed.
