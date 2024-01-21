-- Copyright Alex Stefanov (umnikos) 2024 
-- Licensed under GPLv3


--print(x,y,z)
m = peripheral.wrap("back")
c = m.canvas3d()

modem = peripheral.find("modem")
port = 6543
modem.open(port)

coroutines = {}
filters = {}
local function coroutine_add(f)
    local i = #coroutines + 1
    local co = coroutine.create(f)
    coroutines[i] = co
    local _,filter = coroutine.resume(co)
    filters[i] = filter
    return i
end
local function coroutine_manager()
    while true do
        local e = table.pack(os.pullEventRaw())
        if e[1] == "terminate" then
            break
        end
        for i,co in pairs(coroutines) do
            if coroutine.status(co) ~= "dead" then
                if filters[i] == nil or e[1] == filters[i] then
                    local _,filter = coroutine.resume(co, table.unpack(e))
                    filters[i] = filter
                end
            else
                print("yeeting coroutine")
                -- remove dead coroutine
                coroutines[i] = nil
                filters[i] = nil
            end
        end
    end
end

function ownerIsMoving()
    o = m.getMetaOwner()
    return 0 ~= o.deltaPosX or 0 ~= o.deltaPosY or 0 ~= o.deltaPosZ
end

objects = {}
function render(message)
    f = load(message.code)
    if not f then 
        print("invalid") 
        return
    end
    f = setfenv(f,{sleep=sleep})
    local x,y,z
    local o
    while true do
        if ownerIsMoving() then
            sleep(1)
        else
            x,y,z = gps.locate()
            if not x then
                sleep(0.1)
            else
                -- time to act!
                o = c.create({message.x-x,message.y-y,message.z-z})
                sleep(0.1)
                if ownerIsMoving() then
                    -- may be invalid, must retry
                    o.remove()
                else    
                    -- valid! (most likely)
                    break
                end
            end
        end
    end
    local oindex = #objects + 1
    objects[oindex] = o
    ff = function()
        --success = pcall(f,o)
        f(o)
        if success then
            print("success")
        else
            print("fail")
            o.remove()
            objects[oindex] = nil
        end
    end
    local findex = coroutine_add(ff)
    return oindex, findex
end

local rendered_versions = {}
local function renderedVersion(message)
    local pc = rendered_versions[message.pcid]
    if not pc then
        return nil
    end
    local o = pc[message.oid]
    return o
end
local function setRenderedVersion(message,oindex,findex)
    local pc = rendered_versions[message.pcid]
    if not pc then
        pc = {}
        rendered_versions[message.pcid] = pc
    end
    pc[message.oid] = {
        code=message.code,
        x=message.x,
        y=message.y,
        z=message.z,
        oindex=oindex,
        findex=findex
    }
end

local function sameVersion(message,rendered)
    if message.x ~= rendered.x or message.y ~= rendered.y or message.z ~= rendered.z then
        return false
    end
    return message.code == rendered.code
end

local function main()
    while true do
        print("looping")
        repeat 
            event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        until channel == port
        if type(message) == "table" and type(message.code) == "string" then
            local rendered_version = renderedVersion(message)
            if rendered_version == nil then
                print("rendering")
                local oindex,findex = render(message)
                print(oindex)
                print(findex)
                print("end")
                setRenderedVersion(message,oindex,findex)
            else
                if not sameVersion(message,rendered_version) then
                    -- must destroy old object first
                    coroutines[rendered_version.findex] = nil
                    filters[rendered_version.findex] = nil
                    print(rendered_version.oindex)
                    print(rendered_version.findex)
                    objects[rendered_version.oindex].remove()
                    objects[rendered_version.oindex] = nil
                    -- before rendering again
                    print("re-rendering")
                    local oindex,findex = render(message)
                    print(oindex)
                    print(findex)
                    print("end")
                    setRenderedVersion(message,oindex,findex)
                else
                    print("already rendered")
                    -- already rendered, nothing to do
                end
            end
        end
    end
end

coroutine_add(main)
coroutine_manager()

print("cleaning up")
for i,o in pairs(objects) do
    o.remove()
end