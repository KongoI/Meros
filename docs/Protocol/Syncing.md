# Syncing

Syncing is a state between two nodes where one needs to catch up. To initiate syncing, the node missing data (the "syncer") sends `Syncing`. In response, the node which received `Syncing` (the "syncee") sends `SyncingAcknowledged`. The syncer should ignore all messages from the syncee until it receives `SyncingAcknowledged`, in order to not confuse normal network traffic with data relevant to its syncing.

During syncing, the syncer can only send:
- `GetAccountHeight`
- `GetHashesAtIndex`
- `GetVerifierHeight`
- `EntryRequest`
- `MemoryVerificationRequest`
- `BlockRequest`
- `VerificationRequest`
- `SyncingOver`

The syncee can only send:
- `AccountHeight`
- `HashesAtIndex`
- `VerifierHeight`
- `Claim`
- `Send`
- `Receive`
- `Data`
- `Lock`
- `Unlock`
- `MemoryVerification`
- `Block`
- `Verification`
- `DataMissing`

The syncee should also only send messages in direct response to a request from the syncer.

### Syncing and SyncingAcknowledged

Both `Syncing` and `SyncingAcknowledged` have a message length of 0. After receiving `SyncingAcknowledged`, the syncer may send requests for missing data, one at a time. Sending multiple requests before receiving a response to the first request will lead to undefined behavior.

### GetAccountHeight and AccountHeight

`GetAccountHeight` has a message length of 32 bytes; the Account's 32 byte Ed25519 Public Key, with the expected response being an `AccountHeight`. `AccountHeight` has a message length of 4 bytes; the specified Account's height.

### GetHashesAtIndex and HashesAtIndex

A `GetHashesAtIndex` has a message length of 36 bytes; the Account's 32 byte Ed25519 Public Key followed by the 4 byte nonce, with the expected response being a `HashesAtIndex`. `HashesAtIndex` has a message length of 1 byte, plus a variable amount of bytes for the hashes; the single byte containing the amount of potential Entries at the specified index it's replying with, followed by the 48-byte hashes of each Entry. If there's a confirmed Entry at the specified index, it is the only potential Entry. If there are more than 8 Entries at the specified index, the response should only contain the 8 Entries with the most Merit behind them. In the case of a tie at the 8th position, the node has discretion over which Entry to reply with.

### GetVerifierHeight and VerifierHeight

`GetAccountHeight` has a message length of 48 bytes; the Verifier's 48 byte BLS Public Key, with the expected response being a `VerifierHeight`. `VerifierHeight` has a message length of 4 bytes; the specified Verifier's height.

### EntryRequest

An `EntryRequest` has a message length of 48 bytes; the Entry hash, with the expected response being a `Claim`, `Send`, `Receive`, or `Data` containing the Entry with the same hash. If a Mint has the requested hash, the syncer should send `DataMissing`.

### MemoryVerificationRequest

A `MemoryVerificationRequest` has a message length of 52 bytes; the Verifier's 48 byte BLS Public Key followed by the 4 byte nonce of the Verification, with the expected response being a `MemoryVerification` containing the MemoryVerification at the requested location. If a verifier had multiple Verifications at that location, the syncee should respond with a `MeritRemoval` containing any 2 MemoryVerifications at that index.

### BlockRequest

A `BlockRequest` is followed by the 48 byte Block hash, with the expected response being a `Block` containing the Block. If a 0'd out hash is provided, the syncee should respond with a `Block` containing their tail Block.

### VerificationRequest

A `VerificationRequest` is identical to a `MemoryVerificationRequest`, except for the fact that if a Verifier has a singular Verification at the requested nonce, the expected response is a `Verification` containing the Verification at the requested location.

### DataMissing

`DataMissing` has a message length of 0 and is a valid response to any request. It signifies the syncee doesn't have the requested data.

### SyncingOver

`SyncingOver` has a message length of 0 and ends syncing.

### Violations in Meros

- Meros doesn't support the `GetAccountHeight` and `AccountHeight` message types.
- Meros doesn't support the `GetHashesAtIndex` and `HashesAtIndex` message types.
- Meros doesn't support the `GetVerifierHeight` and `VerifierHeight` message types.
- Meros doesn't support the `MemoryVerificationRequest` message type.
- A `BlockRequest` is followed by 4 bytes representing the nonce of the Block, as Meros currently doesn't support chain reorgs in any form. To get the tail Block, Meros sends 4 0 bytes.