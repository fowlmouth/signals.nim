
import signals, strutils

type Light* = ref object of TObject
  state: bool

proc toggle (L:Light) =
  L.state = not L.state
proc turnOff (L:Light)= L.state = off
proc turnOn  (L:Light)= L.state = on



var
  sw1, sw2: PSignal[void]
sw1.init
sw2.init

var
  allOff,allOn: PSignal[void]
allOff.init
allOn.init

template con_m (L): stmt =
  connect( allOff, L) do (self: type(L)):
    turnOff self
  connect( allOn, L ) do (self: type(L)):
    turnOn self

var
  L1 = Light(state:off)
  L2 = Light(state:on)

con_m L1
con_m L2

block:
  template show_lights : stmt =
    echo "  Light1: $#  Light2: $#".format(
      L1.state, L2.state                  )
  
  echo "Initial State:"
  show_lights
  
  sw1.connect L1, toggle
  
  sw2.connect L1, toggle
  sw2.connect L2, toggle
  
  echo "Hitting Switch1 (Light1)."
  sw1()
  
  show_lights
  
  echo "Hitting Switch2 (Light1 and Light2)."
  sw2()
  
  show_lights

L1.state = off
L2.state = off

type LightSlotted* = ref object of Light
  slots*: seq[PSignalBase]

assert LightSlotted is HasSlots

let L3 = LightSlotted(state:off, slots: @[])
let L4 = LightSlotted(state:off, slots: @[])

assert L3 is HasSlots


block:
  template show_lights: stmt =
    echo " 1: $#  2: $#  3: $#  4: $#".format(
      L1.state,L2.state,L3.state,L4.state    )
  
  echo "Connecting L3 and L4."
  con_m L3
  con_m L4
  sw1.connect( L3 ) do (L:LightSlotted): toggle L 
  sw1.connect( L4 ) do (L:LightSlotted): toggle L
  
  show_lights
  
  echo "allOn()"
  allOn.emit
  show_lights
  
  echo "allOff()"
  allOff.emit
  show_lights
  
  ## backref test
  
  echo "Disconnecting L3."
  L3.clearSignals
  echo "allOn()"
  allOn.emit
  show_lights
  
  
  var sig_arg = initSignal[int]()
  sig_arg.connect(L3) do (L: LightSlotted, I: int):
    echo I
  sig_arg(42)
  L3.clearSignals
  sig_arg(9001)
  # great

when false:
  echo "\L--- GC TEST ---"
  
  var displayUpdate = initSignal[void]()
  
  type GCO = ref object of TObject
   id : int
   
  var counter = 0
  proc newGCO : GCO = 
    result.new do (x:GCO):
      echo "Free'd GCO #", x.id
    result.id = counter
    counter.inc
  proc display (x: GCO) =
    echo "display #",x.id
  
  block:
    for i in 0 .. 5:
      let x = newGCO()
      displayUpdate.connect x, display
    
    displayUpdate()
    gc_fullCollect()
    displayUpdate.clear
    gc_fullCollect()
    echo "GC should be done! signal has been cleared."
    displayUpdate()
    gc_fullCollect()
