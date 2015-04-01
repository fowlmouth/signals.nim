
type
  TSignalCon [Arg] = object
    obj: ref TObject
    f: proc(x: Arg)

  SignalBase* = ref object of RootObj
    ## Base signal for storage in "slots" accessor
  Signal* [Arg] = ref object of SignalBase
    con: seq[TSignalCon[Arg]]

  HasSlots* = generic X
    X is RootRef
    X.slots is seq[PSignalBase]
  
  SlottedObj* = object of RootObj
    # a base type you can use that fulfils HasSlots
    slots*: seq[SignalBase]

{.deprecated: [
  PSignal: Signal, 
  PSignalBase: SignalBase,
  PSlotted: SlottedObj
].}

proc `==` * [ArgT] (con:TSignalCon[ArgT]; obj: ref TObject): bool =
  con.obj == obj
proc disconnect* [T,ArgT] (sig:PSignal[ArgT]; obj: T) {.inline.} =
  while(let idx = sig.con.find(obj); idx != -1):
    when T is HasSlots:
      if (let idx = obj.slots.find(sig); idx != -1):
        obj.slots.del idx
    sig.con.del idx

proc clear* [ArgT] (sig: PSignal[ArgT]) {.inline.}
proc init* [ArgT] (sig: var PSignal[ArgT]) {.inline.}=
  if sig.isNil:
    new(sig) do (x: PSignal[ArgT]):
      x.clear
  sig.con.newSeq 0
proc initSignal*[ArgT] : PSignal[ArgT] {.inline.}=
  result.init

proc connect* [T, ArgT] (
      sig: PSignal[ArgT]; 
      obj: T; 
      f: proc(self: T; arg: ArgT)) {.inline.}=
  let fn = proc(arg: ArgT) = f(obj, arg)
  sig.con.add TSignalCon[ArgT](obj: obj, f: fn)
  when T is HasSlots:
    obj.slots.add sig

proc connect* [T] (
      sig: PSignal[void]; 
      obj: T; 
      f: proc(self: T)){.inline.}=
  let fn = proc() = f(obj)
  sig.con.add TSignalCon[void](obj: obj, f: fn)
  when T is HasSlots:
    obj.slots.add sig

proc connect* (
      sig: PSignal[void];
      f: proc()) {.inline.} =
  sig.con.add TSignalCon[void](obj: nil, f: f)

proc connect* [T] (
      sig: PSignal[T];
      f: proc(arg: T) ) {.inline.} =
  sig.con.add TSignalCon[T](obj: nil, f: f)

proc clear* [ArgT] (sig:PSignal[ArgT]) =
  while sig.con.len > 0:
    sig.disconnect sig.con[0].obj

proc clearSignals* (obj:HasSlots) =
  #
  while obj.slots.len > 0:
    cast[PSignal[void]](obj.slots[0]).disconnect obj



proc emit* [ArgT] (sig: PSignal[ArgT]; arg: ArgT){.inline.}=
  if sig.isNil: return
  for idx in 0 .. < sig.con.len:
    sig.con[idx].f(arg)
proc `()`* [ArgT] (sig: PSignal[ArgT]; arg: ArgT){.inline.} =
  sig.emit(arg)

proc emit* (sig: PSignal[void]) {.inline.} =
  for idx in 0 .. < sig.con.len: sig.con[idx].f()
proc `()`* (sig: PSignal[void]) {.inline.} =
  sig.emit()

  