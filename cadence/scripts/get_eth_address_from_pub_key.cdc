import "ETHUtils"

access(all) fun main(hexPublicKey: String): String {
    return ETHUtils.getETHAddressFromPublicKey(hexPublicKey: hexPublicKey)
}