discard """
Epochs Test 1. Verifies that 1 Verification = 1000.
"""

#BN lib.
import BN

#Hash lib.
import ../../../../src/lib/Hash

#Merkle lib.
import ../../../../src/lib/Merkle

#BLS and MinerWallet libs.
import ../../../../src/lib/BLS
import ../../../../src/Wallet/MinerWallet

#Verifications lib.
import ../../../../src/Database/Verifications/Verifications

#Merit lib.
import ../../../../src/Database/Merit/Merit

#Merit Testing functions.
import ../TestMerit

#String utils standard lib.
import strutils

var
    #Database Function Box.
    functions: DatabaseFunctionBox = newTestDatabase()
    #Verifications.
    verifications: Verifications = newVerifications(functions)
    #Blockchain.
    blockchain: Blockchain = newBlockchain(functions, "EPOCH_TEST_1", 1, newBN(0))
    #State.
    state: State = newState(functions, 100)
    #Epochs.
    epochs: Epochs = newEpochs(functions, verifications, blockchain)

    #Hash.
    hash: Hash[512] = "aa".repeat(64).toHash(512)
    #MinerWallet.
    miner: MinerWallet = newMinerWallet()
    #MemoryVerification object.
    verif: MemoryVerification
    #VerifierIndexes.
    verifs: seq[VerifierIndex] = @[]
    #Rewards.
    rewards: Rewards

#Give Key 0 Merit.
state.processBlock(
    blockchain,
    newTestBlock(
        miners = @[
            newMinerObj(
                miner.publicKey,
                100
            )
        ]
    )
)

#Add a Verification.
verif = newMemoryVerificationObj(hash)
miner.sign(verif, 0)
#Add it the Verifications.
verifications.add(verif)
#Add a VerifierIndex.
verifs.add(newVerifierIndex(
    miner.publicKey.toString(),
    0,
    newMerkle(hash.toString()).hash
))

#Shift on the Verifications.
rewards = epochs.shift(verifications, verifs).calculate(state)
assert(rewards.len == 0)

#Shift 5 over.
for _ in 0 ..< 5:
    rewards = epochs.shift(verifications, @[]).calculate(state)
    assert(rewards.len == 0)

#Next shift should result in a Rewards of Key 0, 1000.
rewards = epochs.shift(verifications, @[]).calculate(state)
assert(rewards.len == 1)
assert(rewards[0].key == miner.publicKey.toString())
assert(rewards[0].score == 1000)

echo "Finished the Database/Merit/Epochs Test #1."
