# iDar-OS Boot & Initialization Wiki

## Introduction

The **iDar-OS Boot System** is the secure startup chain responsible for initializing virtual hardware, setting up the isolated execution environment (Loom), and managing core system daemons. It ensures a safe transition from the host environment to the sandboxed user space.

## Core Concepts

### The Three Pillars of Initialization

1. **The Master Boot Record (`MBR.lua`)** - The primary entry point running in the host space. It generates unique hardware identifiers (like deterministic MAC addresses), manages global configurations, and boots the Loom hypervisor.
2. **The Init System (`init.lua`)** - The first sandboxed process (PID 1). It reads the virtualized autostart configurations, launches background services, and guarantees a persistent Shell session.
3. **The TTY Daemon (`tty_daemon.lua`)** - The input multiplexer. It captures global user inputs and securely routes them only to the active foreground process, preventing background apps from intercepting keystrokes.

## Execution Guide

### The Boot Sequence

The boot process follows a strict privilege drop sequence to ensure system stability and security:

1. **Hardware Initialization:** `MBR.lua` checks for or creates `/iDar/etc/hardware.lua`. It derives a unique MAC address using the Computer ID as a seed.
2. **Global APIs:** The bootloader registers the `_G.iDarBoot` API into the global environment for system-level configuration access.
3. **Hypervisor Handoff:** `MBR.lua` registers `init.lua` as the first process using `loom.launch("/boot/src/init.lua")` and hands over control to the kernel with `loom.execute()`.
4. **Service Startup:** Inside the Loom sandbox, `init.lua` reads the chrooted config `/etc/autostart.conf` and spawns all registered background services.
5. **Daemon & Shell Lifecycle:** `init.lua` spawns the TTY Daemon and enters an infinite loop to spawn and monitor the Shell. If the Shell crashes or exits, the Init system automatically respawns it after 1 second.

## System Configuration

The Boot system relies on specific configuration files to maintain state across reboots.

| File Path (Host)          | Virtual Path (Loom)   | Description                                                                                         |
| :------------------------ | :-------------------- | :-------------------------------------------------------------------------------------------------- |
| `/iDar/etc/hardware.lua`  | _N/A (Abstracted)_    | Stores persistent hardware data like `computer_id`, `mac_address`, and generation timestamps.       |
| `/iDar/etc/autostart.lua` | `/etc/autostart.conf` | A serialized table mapping service names to their executable paths. Read by `init.lua` during boot. |

## Bootloader APIs

Before handing control over to Loom, the MBR exposes the `_G.iDarBoot` API. This allows the system to query hardware states securely.

- **`iDarBoot.register(service_name, config)`:** Safely adds or updates a service entry in the `autostart.lua` file.
- **`iDarBoot.getMac()`:** Returns the unique, deterministic MAC address generated for the current computer.
- **`iDarBoot.getHardware()`:** Returns the complete hardware configuration table.
- **`iDarBoot.getVersion()`:** Returns the current bootloader version (e.g., `"Alpha v0.01"`).

## Input Multiplexing (TTY Daemon)

### Foreground Process Management

To prevent multiple sandboxed applications from competing for keyboard input, the **TTY Daemon** acts as a traffic controller:

- It listens for raw OS events (`char`, `key`, `key_up`).
- It maintains an internal `foreground_pid` variable (defaulting to PID 3, usually the Shell).
- It repackages the events and queues them back into the Loom scheduler with a prefix specific to the active PID (e.g., `"fg_key_3"`).
- Processes can request focus by emitting a `"set_foreground"` event along with their PID, allowing the daemon to seamlessly switch input routing between different user interfaces.
