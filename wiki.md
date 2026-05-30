# iDar-OS Boot & Initialization Wiki

## Introduction

The **iDar-OS Boot System** is the secure startup chain responsible for initializing virtual hardware, setting up the isolated execution environment (Loom), and managing core system daemons. It ensures a safe transition from the host environment to the sandboxed user space, enforcing strict Ring 0 / Ring 3 security boundaries from the moment the computer turns on.

## Core Concepts

### The Three Pillars of Initialization

1. **The Master Boot Record (`MBR.lua`)** - The primary entry point running in the host space. It generates unique hardware identifiers (like deterministic MAC addresses), manages global configurations, and boots the Loom microkernel.
2. **The Init System (`init.lua`)** - The first sandboxed process (PID 1). Running with elevated privileges (**UID 0 / root**), it reads the virtualized autostart configurations securely through the Virtual File System (VFS), launches background services, and guarantees persistent Shell sessions.
3. **The TTY Daemon (`tty_daemon.lua`)** - The input multiplexer and virtual terminal manager. It captures global user inputs, securely routes them only to the active foreground process, and manages switching between multiple virtual shell sessions.

## Execution Guide

### The Boot Sequence

The boot process follows a strict privilege drop sequence to ensure system stability and security:

1. **Hardware Initialization:** `MBR.lua` checks for or creates `/iDar/etc/hardware.conf`. It derives a unique MAC address using the internal Computer ID as a mathematical seed.
2. **Global APIs:** The bootloader registers the read-only `_G.iDarBoot` API into the global environment for system-level configuration access.
3. **Kernel Handoff:** `MBR.lua` registers `init.lua` as the first process using `loom.launch("/boot/init.lua")` and hands over control to the kernel with `loom.execute()`.
4. **Service Startup (PID 1):** Inside the Loom sandbox, `init.lua` executes as **UID 0**. It uses safe syscalls (`sys.open`, `sys.read`) to read the chrooted config `/etc/autostart.conf` and spawns all registered background services via `sys.spawn()`, passing the appropriate UID configurations.
5. **Daemon & Shell Lifecycle:** `init.lua` spawns the TTY Daemon (`/boot/tty_daemon.lua`) and enters an infinite loop. If the daemon crashes or exits, the Init system catches the signal and automatically respawns it to prevent the system from becoming unresponsive.

## System Configuration

The Boot system relies on specific configuration files to maintain state across reboots. These files are managed automatically by the MBR.

| File Path (Host)           | Virtual Path (Loom)   | Description                                                                                         |
| :------------------------- | :-------------------- | :-------------------------------------------------------------------------------------------------- |
| `/iDar/etc/hardware.conf`  | _N/A (Abstracted)_    | Stores persistent hardware data like `computer_id`, `mac_address`, and generation timestamps.       |
| `/iDar/etc/autostart.conf` | `/etc/autostart.conf` | A serialized table mapping service names to their executable paths. Read by `init.lua` during boot. |

**Security Note:** Because of Loom's UID permission system, standard user processes (Ring 3) cannot write to `/etc/autostart.conf`. Modifying startup services requires elevated privileges via `sys.sudo` to access the `/etc/` directory.

## Bootloader APIs

Before handing control over to Loom, the MBR exposes the `_G.iDarBoot` API. This allows the system to query hardware states securely from within sandboxed applications.

- **`iDarBoot.getMac()`:** Returns the unique, deterministic MAC address generated for the current computer.
- **`iDarBoot.getHardware()`:** Returns the complete hardware configuration table (including labels and boot timestamps).
- **`iDarBoot.getVersion()`:** Returns the current bootloader version (e.g., `"Alpha v2"`).

_(Security Notice: In previous versions, this API allowed service registration via `_G`. This feature was removed to prevent privilege escalation. System services must now be managed directly through the VFS using root privileges)._

## Input Multiplexing (TTY Daemon)

### Virtual Terminals and Foreground Control

To prevent multiple sandboxed applications from competing for keyboard input, the **TTY Daemon** acts as a traffic controller running in the background:

- **Virtual TTYs:** The daemon spawns multiple login shells in the background. Users can switch between these active sessions seamlessly using `Ctrl + 1-6` (mapped securely using the native `keys` API to avoid Java version conflicts).
- **Event Interception:** It runs parallel listeners to intercept raw OS events (`char`, `key`, `key_up`).
- **Secure Routing:** It maintains an internal `current_fg_pid` variable that tracks which process currently owns the screen. It repackages the events and queues them back into the Loom scheduler with a specific prefix directed _only_ at the active PID (e.g., `"fg_char_3"`, `"fg_key_3"`).
- **Focus Requests:** Any sandboxed process can request input focus by having the system emit a `"set_foreground"` event along with its PID (handled natively via `sys.set_foreground(pid)`), allowing the daemon to seamlessly switch input routing between different interfaces.
