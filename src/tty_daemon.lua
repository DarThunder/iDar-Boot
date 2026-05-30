local shell_pids = {
    sys.spawn("/opt/Shell/shell_programs/login.lua", { inherit_tty = false }),
    sys.spawn("/opt/Shell/shell_programs/login.lua", { inherit_tty = false }),
    sys.spawn("/opt/Shell/shell_programs/login.lua", { inherit_tty = false }),
    sys.spawn("/opt/Shell/shell_programs/login.lua", { inherit_tty = false }),
    sys.spawn("/opt/Shell/shell_programs/login.lua", { inherit_tty = false }),
    sys.spawn("/opt/Shell/shell_programs/login.lua", { inherit_tty = false }),
}

local tty_keys = {
    [keys.one] = 1, [keys.two] = 2, [keys.three] = 3,
    [keys.four] = 4, [keys.five] = 5, [keys.six] = 6
}

local current_fg_pid = shell_pids[1]
sys.set_foreground(current_fg_pid)

local ctrl_held = false

local function focus_listener()
    while true do
        local _, target_pid = os.pullEvent("set_foreground")
        current_fg_pid = target_pid
    end
end

local function input_handler()
    while true do
        local event_data = table.pack(os.pullEvent())
        local event = event_data[1]

        if event == "key" and (event_data[2] == keys.leftCtrl or event_data[2] == keys.rightCtrl) then
            ctrl_held = true
        elseif event == "key_up" and (event_data[2] == keys.leftCtrl or event_data[2] == keys.rightCtrl) then
            ctrl_held = false
        end

        local is_tty_switch = false

        if event == "key" and ctrl_held then
            local target_pid = nil
            local target_index = tty_keys[event_data[2]]
            if target_index then
                target_pid = shell_pids[target_index]
            end

            if target_pid then
                is_tty_switch = true
                if current_fg_pid ~= target_pid then
                    sys.set_foreground(target_pid)
                end
            end
        end

        if not is_tty_switch and (event == "char" or event == "key" or event == "key_up") then
            if current_fg_pid then
                os.queueEvent("fg_" .. event .. "_" .. current_fg_pid, event_data[2], event_data[3])
            end
        end
    end
end

parallel.waitForAll(focus_listener, input_handler)