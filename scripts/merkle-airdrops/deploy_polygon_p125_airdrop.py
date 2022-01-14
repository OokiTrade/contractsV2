zeroAirdrops = {
    "merkleRoot": "0xb3235d5dfc28bd887586bb2092fe1b5fe2d2d87921115aa879cfa611427e02b9",
    "tokenTotal": "0x01",
    "claims": {
        "0xAF3f706F43207a8EE376FaFa070a7584C9A0304c": {
            "index": 0,
            "amount": "0x01",
            "proof": []
        }
    }
}

BZRX = Contract.from_abi("BZRX", address="0x54cFe73f2c7d0c4b62Ab869B473F5512Dc0944D2", abi=TestToken.abi)
P125 = Contract.from_abi("P125", address="0x83000597e8420aD7e9EDD410b2883Df1b83823cF", abi=TestToken.abi)


multisign = '0x01F569df8A270eCA78597aFe97D30c65D8a8ca80'
merkleRoot0="0xb3235d5dfc28bd887586bb2092fe1b5fe2d2d87921115aa879cfa611427e02b9"
merkleRoot1="0x30576322d674b506064d93edec21e3d3ad893af48ed3c8098b69a5ed5a50013d"
merkleRoot2="0x823841b93064b4224d87e4b4891117c75a15230149f6b58d4f473d5f30d48e05"

merkle = Contract.from_abi("merkle", address="0x59a6579C039F84A758665Ca416394BdF6A05985d", abi=MerkleDistributor.abi)
owner = accounts[11]
tokenTotal0 = 0x01
tokenTotal1 = 54560458426309067054193525
tokenTotal2 = 148041752274953210925446

#BZRX (dummy airdropindex)
merkle.createAirdrop(BZRX, merkleRoot0, multisign, tokenTotal0, {'from': owner})
#P125
merkle.createAirdrop(P125, merkleRoot1, multisign, tokenTotal1, {'from': owner})
#BZRX
merkle.createAirdrop(BZRX, merkleRoot2, multisign, tokenTotal2, {'from': owner})


merkle.transferOwnership(multisign, {'from': owner})
multisign = '0x01F569df8A270eCA78597aFe97D30c65D8a8ca80'
P125.approve(merkle, tokenTotal1, {'from': multisign})
BZRX.approve(merkle, tokenTotal2+tokenTotal0, {'from': multisign})
