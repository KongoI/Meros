#Types.
from typing import Dict, Any

#Element class.
from PythonTests.Classes.Consensus.Element import Element

#BLS lib.
import blspy

#Verification class.
class Verification(Element):
    #Constructor.
    def __init__(
        self,
        txHash: bytes,
        holder: int
    ) -> None:
        self.prefix: bytes = b'\0'

        self.hash: bytes = txHash
        self.holder: int = holder

    #Element -> Verification. Satisifes static typing requirements.
    @staticmethod
    def fromElement(
        elem: Element
    ) -> Any:
        return elem

    #Serialize.
    def serialize(
        self
    ) -> bytes:
        return self.holder.to_bytes(2, "big") + self.hash

    #Verification -> JSON.
    def toJSON(
        self
    ) -> Dict[str, Any]:
        return {
            "descendant": "Verification",

            "hash": self.hash.hex().upper(),
            "holder": self.holder
        }

    #JSON -> Verification.
    @staticmethod
    def fromJSON(
        json: Dict[str, Any]
    ) -> Any:
        return Verification(bytes.fromhex(json["hash"]), json["holder"])

class SignedVerification(Verification):
    #Constructor.
    def __init__(
        self,
        txHash: bytes,
        holder: int = 0,
        signature: bytes = bytes(96)
    ) -> None:
        Verification.__init__(self, txHash, holder)
        self.signature: bytes = signature

    #Sign.
    def sign(
        self,
        holder: int,
        privKey: blspy.PrivateKey
    ) -> None:
        self.holder = holder
        self.signature = privKey.sign(self.prefix + self.hash).serialize()

    #Serialize.
    def signedSerialize(
        self
    ) -> bytes:
        return Verification.serialize(self) + self.signature

    #SignedVerification -> SignedElement.
    def toSignedElement(
        self
    ) -> Any:
        return self

    #SignedVerification -> JSON.
    def toSignedJSON(
        self
    ) -> Dict[str, Any]:
        return {
            "descendant": "Verification",

            "holder": self.holder,
            "hash": self.hash.hex().upper(),

            "signed": True,
            "signature": self.signature.hex().upper()
        }

    #JSON -> Verification.
    @staticmethod
    def fromJSON(
        json: Dict[str, Any]
    ) -> Any:
        return SignedVerification(
            bytes.fromhex(json["hash"]),
            json["holder"],
            bytes.fromhex(json["signature"])
        )
