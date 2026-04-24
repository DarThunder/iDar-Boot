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

print("Starting TTY Daemon...")
sys.spawn("/boot/tty_daemon.lua")

while true do
    print("Starting Shell session...")
    local shell_pid = sys.spawn("/opt/Shell/shell.lua")

    sys.set_foreground(shell_pid)
    sys.wait(shell_pid)
    sys.set_foreground(sys.get_pid())

    print("Shell exited. Respawning in 1 second...")
    sleep(1)
end