modem = peripheral.wrap("top") -- wireless modem on top
local x,y,z
x,y,z = gps.locate()
while not x do
    sleep(1)
    x,y,z = gps.locate()
end
print("gps coords obtained")
print(x)
print(y)
print(z)
local pcid = os.getComputerID()

-- the object that will be sent and what id the computer assigns to it
-- multiple objects can be sent from the same computer if they get given different ids
local oid = 1
local f = fs.open("object.lua","r")
local code = f.readAll()
f.close()

transmit_port = 6543
function send(message)
    modem.transmit(transmit_port, 0, message)
end
print("transmitting")
while true do
    send({x=x,y=y,z=z,pcid=pcid,oid=oid,code=code})
    sleep(1)
end
