local loom = require("iDar.opt.Loom.core")

local boot = {}
local hardware_file = nil
local auto_file = nil

local function derive_mac()
    local seed = os.getComputerID() * 0xE11F8FB4
    local bytes = {}
    for i = 1, 6 do
        seed = bit.band((seed * 1103515245 + 12345), 0xFFFFFFFF)
        bytes[i] = bit.band(seed, 0xFF)
    end
    bytes[1] = bit.bor(bit.band(bytes[1], 0xFE), 0x02)
    return string.format('%02x:%02x:%02x:%02x:%02x:%02x', table.unpack(bytes))
end

local function create_hardware_file()
    local configs = {
        computer_id = os.getComputerID(),
        computer_label = os.getComputerLabel(),
        mac_address = derive_mac(),
        generated_at = os.epoch("utc"),
        boot_version = "0.01"
    }
    local f = io.open("/iDar/etc/hardware.conf", "w")

    if not f then error("Can't Open hardware file, closing...") return end

    f:write(textutils.serialize(configs))
    f:close()

    return true
end

local function get_hardware()
    local f = io.open("/iDar/etc/hardware.conf", "r")

    if not f then error("Can't Open hardware file, closing...") return end

    local config = f:read("a")
    f:close()

    hardware_file = textutils.unserialize(config)
end

local function save_config()
    local f = io.open("/iDar/etc/autostart.conf", "w")

    if not f or not auto_file then error("Can't Open hardware file, closing...") return end

    f:write(textutils.serialize(auto_file))
    f:close()

    return true
end

local function get_config()
    local f = io.open("/iDar/etc/autostart.conf", "r")

    if not f then error("Can't Open hardware file, closing...") return end

    local config = f:read("a")
    f:close()

    auto_file = textutils.unserialize(config)
end

function boot.register(service_name, config)
    if not auto_file or type(auto_file) ~= "table" then return false end
    auto_file[service_name] = config
    save_config()
    return true
end

function boot.getMac()
    if not hardware_file or type(hardware_file) ~= "table" then return nil end
    return hardware_file.mac_address
end

function boot.getHardware()
    return hardware_file
end

function boot.getVersion()
    return "Alpha v0.01"
end

local function init_system()
    if not fs.exists("/iDar/etc/hardware.conf") then
        create_hardware_file()
    end
    get_hardware()

    if not fs.exists("/iDar/etc/autostart.conf") then
        auto_file = {}
        save_config()
    end
    get_config()
end

init_system()
_G.iDarBoot = boot

loom.launch("/boot/init.lua")

term.clear()
term.setCursorPos(1, 1)

loom.execute()