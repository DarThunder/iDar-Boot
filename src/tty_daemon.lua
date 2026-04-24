local foreground_pid = 3

while true do
    local event_data = table.pack(os.pullEvent())
    local event = event_data[1]

    if event == "set_foreground" then
        foreground_pid = event_data[2]

    elseif event == "char" or event == "key" or event == "key_up" then
        os.queueEvent("fg_" .. event .. "_" .. foreground_pid, event_data[2], event_data[3])
    end
end