return {
    files = {
        ["init.lua"] = "src/init.lua",
        ["MBR.lua"] = "src/MBR.lua",
        ["tty_daemon.lua"] = "src/tty_daemon.lua"
    },

    dependencies = {
        { name = "idar-loom", version = "latest" }
    },
}