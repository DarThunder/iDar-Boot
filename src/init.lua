print("iDar-OS Init System starting...")

local f = sys.open("/etc/autostart.conf", "r")
if f then
    local content = sys.read(f)
    sys.close(f)
    if content then
        local auto_file = textutils.unserialize(content)
        for service, path in pairs(auto_file) do
            if sys.exists(path) then
                print("Starting service: " .. service)
                sys.spawn(path)
            end
        end
    end
end

while true do
    print("Starting TTY Daemon (Multiplexer)...")

    local daemon_pid = sys.spawn("/boot/tty_daemon.lua", { uid = 0, superrr = 2 })

    sys.wait(daemon_pid)

    print("CRITICAL: TTY Daemon exited or crashed! Respawning in 1 second...")
    sleep(1)
end