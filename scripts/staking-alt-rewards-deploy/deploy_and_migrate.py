exec(open("./scripts/env/set-eth.py").read())
STAKING = Contract.from_abi("STAKING_ADM", STAKING, StakeUnstake.abi)
STAKING_ADM = Contract.from_abi("STAKING_ADM", STAKING, AdminSettings.abi)
STAKING_PROXY = Contract.from_abi("STAKING_PROXY", STAKING, StakingModularProxy.abi)



#admImpl = AdminSettings.deploy({'from': STAKING.owner()})
admImpl = AdminSettings.at("0x07568fc73918d302935411d5c1244251e5e0a41d")

#stakingImpl = StakeUnstake.deploy( {'from': STAKING.owner()})
stakingImpl = StakeUnstake.at("0x7e2bf18732b45ad724e9d089b597d13bb2269f76")
arr = []

STAKING_PROXY.replaceContract(stakingImpl, {'from': STAKING.owner()})
STAKING_PROXY.replaceContract(admImpl, {'from': STAKING.owner()})
STAKING_ADM.migrateSushi(335, '0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd', 50, '0xEF0881eC094552b2e128Cf945EF17a6752B4Ec5d', {'from': STAKING.owner()})
STAKING_ADM.setAltRewardsUserInfo(
    [
        "0xd4aeb7f67e0aee2ecb8ad45a8b9e89afea8a591e",
        "0xe487a866b0f6b1b663b4566ff7e998af6116fba9",
        "0x9be80c23245b576b23c01670137726fef0f9b64e",
        "0xfc67418ff4ffb7f39769587bfd425d750b9f0663",
        "0x1ab8d5270ff8fdf09e708f42405a48da2ef1d60c",
        "0x87fddf2b1a88e4332914f2aad3a2765374522f21",
        "0x42a3fdad947807f9fa84b8c869680a3b7a46bee7",
        "0x57b3c8623e43e4fb17d526179d10e0d8a4a81e53",
        "0x6f9bb7e454f5b3eb2310343f0e99269dc2bb8a1d"
    ],
    [
        14115768,
        14126130,
        14131614,
        14133226,
        14183871,
        14315460,
        14727891 + 900000,
        14727891 + 900000,
        14665638
    ],
    {'from': STAKING.owner()}
)
