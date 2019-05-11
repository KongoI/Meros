#Errors lib.
import ../../../lib/Errors

#Util lib.
import ../../../lib/Util

#MinerWallet lib (for BLSPublicKey).
import ../../../Wallet/MinerWallet

#DB Function Box object.
import ../../../objects/GlobalFunctionBoxObj

#Finals lib.
import finals

#Tables standard lib.
import tables

#State object.
finalsd:
    #This cannot be a ref object due to how we copy it for reversions.
    type State* = object
        #DB.
        db: DatabaseFunctionBox
        #String of every holder.
        holdersStr: string
        #List of unsaved accounts.
        pending: seq[string]

        #Blocks until Merit is dead.
        deadBlocks* {.final.}: Natural
        #Live Merit.
        live: Natural

        #Amount of Blocks processed.
        processedBlocks*: int
        #BLSPublicKey -> Merit
        holders: Table[string, int]

#Constructor.
proc newStateObj*(
    db: DatabaseFunctionBox,
    deadBlocks: Natural
): State {.forceCheck: [].} =
    result = State(
        db: db,
        pending: @[],

        deadBlocks: deadBlocks,
        live: 0,

        processedBlocks: 1,
        holders: initTable[string, int]()
    )
    result.ffinalizeDeadBlocks()

    #Load the live Merit and the holders from the DB.
    try:
        result.live = result.db.get("state_live").fromBinary()
        result.processedBlocks = result.db.get("state_processed").fromBinary()
        result.holdersStr = result.db.get("state_holders")
    #If these don't exist, confirm we didn't load one but not the other.
    except DBReadError:
        if result.live != 0:
            doAssert(false, "Loaded the amount of live Merit but not the amount of processed blocks or any holders from the database.")

    #Handle each holder.
    var holder: string
    for i in countup(0, result.holdersStr.len - 1, 48):
        #Extract the holder.
        holder = result.holdersStr[i .. i + 47]
        #Load their balance.
        try:
            result.holders[holder] = result.db.get("state_" & holder).fromBinary()
        except DBReadError as e:
            doAssert(false, "Couldn't load a holder's state: " & e.msg)

#Add a Holder to the State.
func add(
    state: var State,
    key: string
) {.forceCheck: [].} =
    #Return if they are already in the state.
    if state.holders.hasKey(key):
        return

    #Add them to the table.
    state.holders[key] = 0

    #Add them to the holders' string.
    state.holdersStr &= key

#Getters.
func `[]`*(
    state: var State,
    key: string
): int {.forceCheck: [].} =
    #Add this holder to the State if they don't exist already.
    state.add(key)

    #Return their value.
    try:
        result = state.holders[key]
    except KeyError as e:
        doAssert(false, "State threw a KeyError when getting a value, despite calling add before attempting." & e.msg)

func `[]`*(
    state: var State,
    key: BLSPublicKey
): int {.inline, forceCheck: [].} =
    state[key.toString()]

#Return the amount of live Merit.
func live*(
    state: State
): int {.inline, forceCheck: [].} =
    state.live

#Setters.
func `[]=`*(
    state: var State,
    key: string,
    value: Natural
) {.forceCheck: [].} =
    #Get the previous value (uses the State `[]` so `add` is called).
    var previous: int = state[key]
    #Set their new value.
    state.holders[key] = value
    #Update live accrodingly.
    if value > previous:
        state.live += value - previous
    else:
        state.live -= previous - value

    #Mark them as pending to be saved.
    state.pending.add(key)

func `[]=`*(
    state: var State,
    key: BLSPublicKey,
    value: Natural
) {.inline, forceCheck: [].} =
    state[key.toString()] = value

#Save the State to the DB.
proc save*(
    state: var State
) {.forceCheck: [].} =
    #Save the State
    try:
        #Iterate over every pending account.
        for key in state.pending:
            #Save the new balance to the DB.
            state.db.put("state_" & key, state[key].toBinary())

        #Clear pending.
        state.pending = @[]

        #Save the new Merit quantity.
        state.db.put("state_live", state.live.toBinary())

        #Save the holdersStr.
        state.db.put("state_holders", state.holdersStr)

        #Save the amount of processed blocks.
        state.db.put("state_processed", state.processedBlocks.toBinary())

    except DBWriteError as e:
        doAssert(false, "Couldn't save the State to the DB: " & e.msg)