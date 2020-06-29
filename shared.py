#!/usr/bin/python3

from munch import Munch

def Constants():
    return Munch({
        "ZERO_ADDRESS": "0x0000000000000000000000000000000000000000",
        "ONE_ADDRESS": "0x0000000000000000000000000000000000000001",
        "MAX_UINT": "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    })

def Addresses():
    return Munch.fromDict({
        "development": {
            "KyberContractAddress": "0x0000000000000000000000000000000000000000",
            "WETHTokenAddress": "0x0b1ba0af832d7c05fd64161e0db78e85978e8082",
            "BZRXTokenAddress": "0x0000000000000000000000000000000000000000",
            "SAITokenAddress": "0x0000000000000000000000000000000000000000",
        },
        "ropsten": {
            "ENSRegistry": "0x112234455c3a32fd11230c42e7bccd4a84e02010",
            "ENSResolver": "0x9C4c3B509e47a298544d0fD0591B47550845e903",
            "OracleNotifier": "0xe09011af509f72c46312ebabceabc7c5ea7e6991",
            "KyberContractAddress": "0x818E6FECD516Ecc3849DAf6845e3EC868087B755",
            "BZRXTokenAddress": "0xf8b0b6ee32a617beca665b6c5b241ac15b1acdd5",
            "BZRXTokenAddressSale": "0x450e617b88366fde63c18880acbdeb35a5812eee",
            "BZxEtherAddress": "0xa3eBDf66e0292F1d5FD82Ae3fcd92551Ac9dB081",
            "MultiSig": "0x35b94649Bd03D13eF08e999127351Cc52286473C",
            "TokenizedRegistry": "0xd03eea21041a19672e451bcbb413ce8be72d0381",
            "LoanTokenSettings": "0x633a8328ae5947FA5E173Cd5e2c8a838637939c3",
            "LoanTokenSettingsLowerAdmin": "0xfC92Cf77FC3ef447F631a37E341c6803AdCEe622",
            "WETHTokenAddress": "0xc778417e063141139fce010982780140aa0cd5ab",
            "SAITokenAddress": "0xad6d458402f60fd3bd25163575031acdce07538d", # Kyber SAI
            "WBTCTokenAddress": "0x95cc8d8f29d0f7fcc425e8708893e759d1599c97" # Kyber ENG
        },
        "kovan": {
            "bZxProtocol": "0xAbd9372723C735D426D0a760D047206Fe115ee6d", #"0x10fA193fB1d00e3C1033B0BB003AbB5f7a5595bB", #"0xD59bd0Cd1461605C31E1C88543E4DbA1Bf6fcaEC", #"0x14Ce6475946ee20e709042556Eda9B95673f47c0", #"0xCc3d7DF311Ba18DCD3dF09401f3C3E1ED1D52405", #"0x115338E77339d64b3d58181Aa9c0518df9D18022", #"0xa62236aB5825325d7a1F762c389608e84D38f17F",
            "ENSRegistry": "0x9590A50Ee1043F8915FF72C0aCC2Dbc600080d36",
            "ENSResolver": "0x44b92B8F27abAC2ebc9d0C4fa6fF0EEd4E98ba79",
            "WethHelper": "0x3b5bDCCDFA2a0a1911984F203C19628EeB6036e0",
            "BZxProxy": "0x9009e85a687b55b5d6c314363c228803fad32d01",
            "BZxVault": "0xce069b35ae99762bee444c81dec1728aa99afd4b",
            "OracleNotifier": "0xc406f51A23F28D6559e311010d3EcD8A07696a45",
            "KyberContractAddress": "0x692f391bCc85cefCe8C237C01e1f636BbD70EA4D",
            "BZRXTokenAddress": "0xe3e682A8Fc7EFec410E4099cc09EfCC0743C634a",
            "BZxEtherAddress": "0xd0a1e359811322d97991e03f863a0c30c2cf029c",
            "MultiSig": "0x0000000000000000000000000000000000000000",
            "TokenizedRegistry": "0xF1C87dD61BF8a4e21978487e2705D52AA687F97E",
            "LoanTokenSettings": "0xa11A720bdAC34139EF17bD76dC30230777001bDc",
            "LoanTokenSettingsLowerAdmin": "0xa1FB8F53678885D952dcdAeDf63E7fbf1F3e909f",
            "PositionTokenSettingsV2": "0x9039aa76ec9d3a7c9dcec1ee008c7b9b1163f709",
            "PositionTokenLogicV2_Initialize": "0x1665364b226e8aa9e545b613ccded1c4b0834fcf",
            "WETHTokenAddress": "0xd0A1E359811322d97991E03f863a0C30C2cF029C",
            "SAITokenAddress": "0xC4375B7De8af5a38a93548eb8453a498222C4fF2",
            "DAITokenAddress": "0x4f96fe3b7a6cf9725f59d353f723c1bdb64ca6aa",
            "CHAITokenAddress": "0x71DD45d9579A499B58aa85F50E5E3B241Ca2d10d",
            "KNCTokenAddress": "0xad67cB4d63C9da94AcA37fDF2761AaDF780ff4a2",
            "LINKTokenAddress": "0xd40390b1ce132ad0bc3765ad0ee42e04d4c52dd6",
        },
        "rinkeby": {
            "OracleNotifier": "0xDF65BD1Bb78E93B533fd95e9Ce30775Dac023F35",
            "KyberContractAddress": "0xF77eC7Ed5f5B9a5aee4cfa6FFCaC6A4C315BaC76",
            "LoanTokenSettings": "0xebec45f9f4011faf1605a77bae0b4e5188068a1f",
            "LoanTokenSettingsLowerAdmin": "0x47b2150f92e272db622ad3ce9a023c9e076354bc",
            "BZRXTokenAddress": "0xb70ce29af9de22e28509cdcf3e0368b5a550548a",
            "BZxEtherAddress": "0xc778417e063141139fce010982780140aa0cd5ab",
            "MultiSig": "0x0000000000000000000000000000000000000000",
            "WETHTokenAddress": "0xc778417e063141139fce010982780140aa0cd5ab",
            "DAITokenAddress": "0x5592ec0cfb4dbc12d3ab100b257153436a1f0fea", # Compound DAI
            "REPTokenAddress": "0x6e894660985207feb7cf89faf048998c71e8ee89", # Compound REP
        },
        "mainnet": {
            "ENSRegistry": "0x314159265dd8dbb310642f98f50c066173c1259b",
            "ENSResolver": "0xD3ddcCDD3b25A8a7423B5bEe360a42146eb4Baf3",
            "WethHelper": "0x3b5bDCCDFA2a0a1911984F203C19628EeB6036e0",
            "BZxProxy": "0x1cf226e9413addaf22412a2e182f9c0de44af002",
            "BZxVault": "0x8b3d70d628ebd30d4a2ea82db95ba2e906c71633",
            "OracleNotifier": "0x6d20ea6fe6d67363684e22f1485712cfdccf177a",
            "KyberContractAddress": "0x818e6fecd516ecc3849daf6845e3ec868087b755", # Mainnet (https://kyber.network/swap)
            "KyberRegisterWallet": "0xECa04bB23612857650D727B8ed008f80952654ee",
            "BZRXTokenAddress": "0x1c74cff0376fb4031cd7492cd6db2d66c3f2c6b9",
            "BZRXTokenAddressSale": "0x0b12cf7964731f7190b74600fcdad9ba4cac870c",
            "BZxEtherAddress": "0x96CCe310096755f69594212d5D5fB5485577E7d1",
            "MultiSig": "0x758dae5e06e11322c8be3463578150401cd31165",
            "Timelock": "0xbb536eb24fb89b544d4bd9e9f1f34d9fd902bb96",
            "TokenizedRegistry": "0xd8dc30d298ccf40042991cb4b96a540d8affe73a",
            "LoanTokenSettings": "0x776fbb4dbfb4af02e9a72d64ea81453cb383874b",
            "LoanTokenSettingsLowerAdmin": "0x95e92dce515e64ba90da7000b3554919784064bd",
            "PositionTokenSettingsV2": "0xeD1e4EdF6C020efe4fc520cfEb4084aeBE969111",
            "BZxOracleHelper": "0xee14de2e67e1ec23c8561a6fad2635ff1b618db6",
            "WETHTokenAddress": "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
            "SAITokenAddress": "0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359",
            "DAITokenAddress": "0x6b175474e89094c44da98b954eedeac495271d0f",
            "CHAITokenAddress": "0x06AF07097C9Eeb7fD685c692751D5C66dB49c215",
            "USDCTokenAddress": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
            "WBTCTokenAddress": "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
            "BATTokenAddress": "0x0d8775f648430679a709e98d2b0cb6250d2887ef",
            "KNCTokenAddress": "0xdd974d5c2e2928dea5f71b9825b8b646686bd200",
            "MKRTokenAddress": "0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2",
            "REPTokenAddress": "0x1985365e9f78359a9b6ad760e32412f4a445e862",
            "ZRXTokenAddress": "0xe41d2489571d322189246dafa5ebde1f4699f498",
            "LINKTokenAddress": "0x514910771af9ca656af840dff83e8264ecf986ca",
            "SUSDTokenAddress": "0x57ab1ec28d129707052df4df418d58a2d46d5f51", # <- proxy, actual -> "0x57Ab1E02fEE23774580C119740129eAC7081e9D3"
            "USDTTokenAddress": "0xdac17f958d2ee523a2206206994597c13d831ec7",
        }
    })
