import "ETHUtils"

import "StringUtils"
import "AddressUtils"

/// Allows a Flow account to attest an affiliated Ethereum address by storing a signed message containing their Flow
/// address (where the attestation resides) and their Ethereum address along with the public key paired to the private
/// key that signed the message.
///
access(all) contract ETHAffiliatedAccount {

    access(all) let STORAGE_PATH: StoragePath
    access(all) let PUBLIC_PATH: PublicPath

    access(all) let ETHEREUM_MESSAGE_PREFIX: String
    access(all) let MESSAGE_DELIMETER: String

    access(all) struct AttestationMessage {
        access(all) let flowAddress: Address
        access(all) let ethAddress: String

        init(flowAddress: Address, ethAddress: String) {
            self.flowAddress = flowAddress
            self.ethAddress = ethAddress
        }

        access(all) fun toString(): String {
            return ETHAffiliatedAccount.ETHEREUM_MESSAGE_PREFIX
                .concat(self.flowAddress.toString())
                .concat(ETHAffiliatedAccount.MESSAGE_DELIMETER)
                .concat(self.ethAddress)
        }
    }

    access(all) resource Attestation {
        access(all) let hexPublicKey: String
        access(all) let signature: String
        access(all) let message: AttestationMessage

        init(
            hexPublicKey: String,
            signature: String,
            message: AttestationMessage
        ) {
            self.hexPublicKey = hexPublicKey
            self.signature = signature
            self.message = message
        }

        access(all) fun verify(): Bool {
            // Valid signature
            let validSignature: Bool = ETHUtils.verifySignature(
                hexPublicKey: self.hexPublicKey,
                hexSignature: self.signature,
                message: self.message.toString()
            )
            // Valid Flow address
            let validFlowAddress: Bool = self.verifyFlowMessageAddressMatchesOwner()
            // Valid ETH address
            let validETHAddress = self.verifyETHMessageAddressMatchesPublicKey()

            return validSignature && validFlowAddress && validETHAddress
        }

        access(all) fun verifySignature(): Bool {
            return ETHUtils.verifySignature(
                hexPublicKey: self.hexPublicKey,
                hexSignature: self.signature,
                message: self.message.toString()
            )
        }

        access(all) fun verifyFlowMessageAddressMatchesOwner(): Bool {
            return self.owner?.address != nil ? self.message.flowAddress == self.owner!.address : false
        }

        access(all) fun verifyETHMessageAddressMatchesPublicKey(): Bool {
            return self.message.ethAddress == ETHUtils.getETHAddressFromPublicKey(hexPublicKey: self.hexPublicKey)
        }

    }

    access(all) resource interface AttestationManagerPublic {
        access(all) fun borrowAttestation(ethAddress: String): &Attestation?
        access(all) fun verify(ethAddress: String): Bool
    }

    access(all) resource AttestationManager : AttestationManagerPublic {

        access(all) let attestations: @{String: Attestation}

        init() {
            self.attestations <- {}
        }

        destroy() {
            destroy self.attestations
        }

        access(all) fun createAttestation(hexPublicKey: String, signature: String, message: String) {
            pre {
                ETHAffiliatedAccount.verifyETHMessageAddressMatchesPublicKey(hexPublicKey: hexPublicKey, message: message):
                    "Public key does not correspond to the valid ETH address in the message."
                self.attestations[ETHAffiliatedAccount.getMessageParts(message)[1]] == nil:
                    "Attestation already exists for the ETH account"
                ETHAffiliatedAccount.getValidFlowAddressFromMessageString(message) != nil:
                    "Message does not contain a valid Flow address."
            }
            post {
                self.attestations[ETHAffiliatedAccount.getMessageParts(message)[1]] != nil:
                    "Attestation was not created successfully."
            }

            let attestation <- create Attestation(
                hexPublicKey: hexPublicKey,
                signature: signature,
                message: ETHAffiliatedAccount.getAttestationMessageFromMessageString(message)
            )

            let ethAddress = ETHAffiliatedAccount.getMessageParts(message)[1]

            assert(attestation.verify(), message: "Invalid signature provided for attested ETH account")

            self.attestations[ethAddress] <-! attestation
        }

        access(all) fun borrowAttestation(ethAddress: String): &Attestation? {
            return &self.attestations[ethAddress] as &Attestation?
        }

        access(all) fun verify(ethAddress: String): Bool {
            return self.borrowAttestation(ethAddress: ethAddress)?.verify() ?? false
        }
    }

    access(all) fun createManager(): @AttestationManager {
        return <- create AttestationManager()
    }

    access(all) fun getAttestationMessageFromMessageString(_ message: String): AttestationMessage {

        let ethAddress: String = self.getMessageParts(message)[1]

        let flowAddress: Address = self.getValidFlowAddressFromMessageString(message) ?? panic("Message provided an invalid Flow Address")

        return AttestationMessage(flowAddress: flowAddress, ethAddress: ethAddress)
    }

    access(self) fun getMessageParts(_ message: String): [String; 2] {
        // Get the Flow and ETH Address string parts from the message & validate format
        let messageParts: [String] = StringUtils.split(message, self.MESSAGE_DELIMETER)
        assert(messageParts.length == 2, message: "Invalid message format.")

        return [messageParts[0], messageParts[1]]
    }

    access(self) fun getValidFlowAddressFromMessageString(_ message: String): Address? {
        let flowAddressString = self.getMessageParts(message)[0]
        let flowAddress = Address.fromString(flowAddressString) ?? panic("Invalid Flow Address format")

        let currentNetwork: String = AddressUtils.getNetworkFromAddress(self.account.address) ?? panic("Could not find current network")

        if AddressUtils.isValidAddress(flowAddress, forNetwork: currentNetwork) {
            return flowAddress
        } else {
            return nil
        }
    }

    access(self) fun verifyETHMessageAddressMatchesPublicKey(hexPublicKey: String, message: String): Bool {
        return ETHUtils.getETHAddressFromPublicKey(hexPublicKey: hexPublicKey) == self.getMessageParts(message)[1]
    }

    init() {
        self.STORAGE_PATH = /storage/ETHAccountAttestation
        self.PUBLIC_PATH = /public/ETHAccountAttestation

        self.ETHEREUM_MESSAGE_PREFIX = "\u{0019}Ethereum Signed Message:\n"
        self.MESSAGE_DELIMETER = "|"
    }
}
