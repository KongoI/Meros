#Errors lib.
import ../../../lib/Errors

#Util lib.
import ../../../lib/Util

#Hash lib.
import ../../../lib/Hash

#MinerWallet lib.
import ../../../Wallet/MinerWallet

#Verification object.
import ../../../Database/Verifications/objects/VerificationObj

#Serialize/Deserialize functions.
import ../SerializeCommon

#Parse a Verification.
proc parseVerification*(
    verifStr: string
): Verification {.forceCheck: [
    ValueError,
    BLSError
].} =
    #BLS Public Key | Nonce | Entry Hash
    var verifSeq: seq[string] = verifStr.deserialize(
        BLS_PUBLIC_KEY_LEN,
        INT_LEN,
        HASH_LEN
    )
    
    #Create the Verification.
    try:
        result = newMemoryVerificationObj(
            verifSeq[2].toHash(384)
        )
        result.verifier = newBLSPublicKey(verifSeq[0])
        result.nonce = verifSeq[1].fromBinary()
    except BLSError as e:
        fcRaise e
    except ValueError as e:
        fcRaise e
    except FinalAttributeError as e:
        doAssert(false, "Set a final attribute twice when parsing a Verification: " & e.msg)
