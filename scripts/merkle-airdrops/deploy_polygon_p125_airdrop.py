BZRX = Contract.from_abi("BZRX", address="0x54cFe73f2c7d0c4b62Ab869B473F5512Dc0944D2", abi=TestToken.abi)
P125 = Contract.from_abi("P125", address="0x83000597e8420aD7e9EDD410b2883Df1b83823cF", abi=TestToken.abi)

multisign = '0x01F569df8A270eCA78597aFe97D30c65D8a8ca80'
merkleRoot0="0x357e647fefac9c8ac5474e4e821e7d41d6155972251218fe9faef893b3d6aca4"

merkle = Contract.from_abi("merkle", address="0x59a6579C039F84A758665Ca416394BdF6A05985d", abi=MerkleDistributor.abi)
multisign = '0x01F569df8A270eCA78597aFe97D30c65D8a8ca80'
tokenTotal0 = 0x0977e0f72043532ec000

#BZRX
merkle.createAirdrop(BZRX, merkleRoot0, multisign, tokenTotal0, {'from': multisign})

#BZRX.approve(merkle, tokenTotal2+tokenTotal0, {'from': multisign})
