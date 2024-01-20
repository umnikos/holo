-- Copyright Alex Stefanov (umnikos) 2024 
-- Licensed under GPLv3

modem = peripheral.wrap("top")
transmit_port = 6543
function send(message)
    modem.transmit(transmit_port, 0, message)
end
while true do
    send({x=5725,y=31,z=4183,code="args={...} i=args[1].addItem({0,0,0},'minecraft:golden_sword') while true do x,y,z=i.getRotation() i.setRotation(x+5,y,z) sleep(0) end"})
    sleep(1)
end
