local current_fg_pid = nil

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

    if event == "char" or event == "key" or event == "key_up" then
        os.queueEvent("fg_" .. event .. "_" .. current_fg_pid, event_data[2], event_data[3])
    end
end
end

parallel.waitForAll(focus_listener, input_handler)