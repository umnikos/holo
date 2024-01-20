-- Copyright Alex Stefanov (umnikos) 2024 
-- Licensed under GPLv3

local x,y,z
while not x do
    sleep(1)
    x,y,z = gps.locate()
end
--print(x,y,z)
m = peripheral.wrap("back")
c = m.canvas3d()

modem = peripheral.find("modem")
port = 6543
modem.open(port)

local rendered_already = {}

coroutines = {}
filters = {}
local function coroutine_add(f)
    local i = #coroutines + 1
    local co = coroutine.create(f)
    coroutines[i] = co
    local _,filter = coroutine.resume(co)
    filters[i] = filter
end
local function coroutine_manager()
    while true do
        local e = table.pack(os.pullEventRaw())
        if e[1] == "terminate" then
            break
        end
        for i,co in ipairs(coroutines) do
            if coroutine.status(co) ~= "dead" then
                if filters[i] == nil or e[1] == filters[i] then
                    local _,filter = coroutine.resume(co, table.unpack(e))
                    filters[i] = filter
                end
            end
        end
    end
end

function render(message)
    f = load(message.code)
    if not f then 
        print("invalid") 
        return
    end
    f = setfenv(f,{sleep=sleep})
    o = c.create({message.x-x,message.y-y,message.z-z})
    ff = function()
        --success = pcall(f,o)
        f(o)
        if success then
            print("success")
        else
            print("fail")
            o.remove()
        end
    end
    coroutine_add(ff)
end

local function main()
    while true do
        repeat 
            event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        until channel == port
        if type(message) == "table" and type(message.code) == "string" and not rendered_already[message.code] then
            print("rendering")
            render(message)
            print("end")
            
            rendered_already[message.code] = true
        end
    end
end

coroutine_add(main)
coroutine_manager()