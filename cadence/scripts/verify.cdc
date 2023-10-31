import "ETHAffiliatedAccount"

access(all) fun main(flowAddress: Address, ethAddress: String): Bool {
    let account = getAccount(flowAddress)
    let manager = account.getCapability<&{ETHAffiliatedAccount.AttestationManagerPublic}>(
            ETHAffiliatedAccount.PUBLIC_PATH
        ).borrow()
        ?? panic("Could not borrow reference to AttestationManagerPublic from the provided account")
    let attestation = manager.borrowAttestation(ethAddress: ethAddress)
        ?? panic("No attestation found for provided ETH address")
    return attestation.verify()
}