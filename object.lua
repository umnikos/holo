-- example object for holo.lua
args={...}
i=args[1].addItem({0.5,2,0.5},'minecraft:golden_sword')
while true do
  x,y,z=i.getRotation()
  i.setRotation(x+10,y,z)
  sleep(0)
end
