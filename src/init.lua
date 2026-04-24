sys.print("iDar-OS Init System starting...")

local f = sys.open("/etc/autostart.conf", "r")
if f then
    local content = sys.read(f)
    sys.close(f)
    if content then
        local auto_file = textutils.unserialize(content)
        for service, path in pairs(auto_file) do
            if sys.exists(path) then
                sys.print("Starting service: " .. service)
                sys.spawn(path)
            end
        end
    end
end

sys.print("Starting TTY Daemon...")
sys.spawn("/boot/src/tty_daemon.lua")

while true do
    sys.print("Starting Shell session...")
    local shell_pid = sys.spawn("/opt/Shell/src/shell.lua")

    sys.set_foreground(shell_pid)
    sys.wait(shell_pid)
    sys.set_foreground(sys.get_pid())

    sys.print("Shell exited. Respawning in 1 second...")
    sys.sleep(1)
end