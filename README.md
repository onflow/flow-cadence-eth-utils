# Ethereum Signature Verification for Cadence

This guide will show you how to generate a public key, a signature, and a message that can be passed into a Cadence smart contract. This can be achieved using Ethereum JavaScript libraries such as ethers.js or any other Web3 API.

## Requirements
This function depends on the following libraries:

- `ethers.js`: Ethereum's JavaScript library used for interacting with Ethereum's network and its smart contracts.
- `@onflow/fcl`: Flow's JavaScript library used for interacting with Flow's network and its smart contracts.


## Example

```js
try {
    const provider = new ethers.providers.Web3Provider(window.ethereum, "any");
   
    // Send a request to access the user's Ethereum accounts
   	await provider.send("eth_requestAccounts", []);
   
    const signer = provider.getSigner();

    // Define a string message to be signed
    const toSign = `Hello Cadence World!`

    const ethSig = await signer.signMessage(toSign);

    // Remove the '0x' prefix from the signature string
    const removedPrefix = ethSig.replace(/^0x/, '');
   
    // Construct the sigObj object that consists of the following parts
    let sigObj = {
   	 	r: removedPrefix.slice(0, 64),  // first 32 bytes of the signature
    	s: removedPrefix.slice(64, 128),  // next 32 bytes of the signature
    	recoveryParam: parseInt(removedPrefix.slice(128, 130), 16),  // the final byte (called v), used for recovering the public key
  	};

    // Combine the 'r' and 's' parts to form the full signature
    const signature = sigObj.r + sigObj.s;

    // Construct the Ethereum signed message, following Ethereum's \x19Ethereum Signed Message:\n<length of message><message> convention.
    // The purpose of this convention is to prevent the signed data from being a valid Ethereum transaction
    const ethMessageVersion = `\x19Ethereum Signed Message:\n${toSign.length}${toSign}`;

    // Compute the Keccak-256 hash of the message, which is used to recover the public key
  	const messageHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(ethMessageVersion));

    const pubKeyWithPrefix = ethers.utils.recoverPublicKey(messageHash, ethSig);

    // Remove the prefix of the recovered public key
    const pubKey = pubKeyWithPrefix.slice(4);

    // The pubKey, toSign, and signature can now be used to interact with Cadence

} catch (err) {
  	console.error(err);  // Log any errors
}

```

This function does the following:

1. **Set up an Ethereum provider**: Uses window.ethereum, which is provided by MetaMask or other Ethereum wallet extensions.
2. **Request account access**: Asks the user to unlock their Ethereum wallet.
3. **Get a signer**: A signer is an Ethereum account that can sign transactions and messages.
4. **Create a message to sign**: For this example, the message is Hello Cadence World!.
5. **Sign the message**: The signer signs the message.
6. **Clean up the signature**: Removes the '0x' prefix from the signature string.
7. **Create a signature object**: Constructs an object with the signature components.
8. **Create the full signature**: Combines the 'r' and 's' components to form the full signature.
9. **Format the message**: Follows Ethereum's signed message convention to prevent the signed data from being a valid Ethereum transaction.
10. **Hash the message**: Computes the Keccak-256 hash of the message, which will be used to recover the public key.
11. **Recover the public key**: Uses the hashed message and the signature to recover the public key.
12. **Clean up the public key**: Removes the prefix of the recovered public key.



## Usage

You can use this function in any situation where you need to authenticate and verify an Ethereum account in Cadence.


```js
await fcl.query({
    cadence: `
      import ETHUtils from <ADDRESS_HERE>

      pub fun main(hexPublicKey: String, hexSignature: String, message : String): Bool {
          return ETHUtils.verifySignature(hexPublicKey: hexPublicKey, hexSignature: hexSignature, message: message)
      }
    `,
    args: (arg, t) => [arg(pubKey, t.String), arg(signature, t.String), arg(toSign, t.String)],
  });
```

This example queries a Cadence smart contract to verify the Ethereum signature.