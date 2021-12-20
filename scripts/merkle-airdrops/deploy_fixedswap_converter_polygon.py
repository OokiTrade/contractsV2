
deployer = accounts[0]
multisign = '0x01F569df8A270eCA78597aFe97D30c65D8a8ca80'
BZRX = Contract.from_abi("BZRX", address="0x54cFe73f2c7d0c4b62Ab869B473F5512Dc0944D2", abi=TestToken.abi)
OOKI = Contract.from_abi("OOKI", address="0xcd150b1f528f326f5194c012f32eb30135c7c2c9", abi=TestToken.abi)

ookiConverter = FixedSwapTokenConverterNotBurn.deploy(
    [BZRX],
    [10e18], #10 ooki == 1 bzrx
    OOKI,
    BZRX,
    {'from':  deployer}
)

ookiConverter.transferOwnership(multisign, {'from': ookiConverter.owner()})
#
# OOKI.transfer(ookiConverter, 1000000e18, {'from': multisign})
# BZRX.transfer(accounts[2], 1000e18, {'from': multisign})
# BZRX.approve(ookiConverter, 2**256-1, {'from': accounts[2]})
#
# ookiConverter.rescue(OOKI, {'from':ookiConverter.owner()})