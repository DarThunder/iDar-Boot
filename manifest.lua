return {
    files = {
        ["src"] = {
            "init.lua",
            "MBR.lua",
            "tty_daemon.lua"
        }
    },

    dependencies = {
        { name = "idar-loom", version = "latest" }
    },
}