from brownie import *

def test_main():
    #poly_distribute()
    #arbi_distribute()
    #bsc_distribute()
    eth_distribute()

def eth_receive_distribute():
    deployingAddress = '0x55FE002aefF02F77364de339a1292923A15844B8' #large ETH Balance source
    USDCsource = '0x55fe002aeff02f77364de339a1292923a15844b8' #large USDC balance source
    USDC = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48'
    logic = ConvertAndAdminister.deploy({'from':deployingAddress})
    proxy = Proxy_0_8.deploy(logic.address,{'from':deployingAddress})
    Distribution = Contract.from_abi('Distribution',proxy.address,ConvertAndAdminister.abi)
    interface.IERC20(USDC).transfer(Distribution.address,100000e6,{'from':USDCsource}) #100k USDC
    Distribution.setApprovals(USDC,Distribution.pool3.call(),100000000e6,{'from':deployingAddress})
    Distribution.setApprovals(Distribution.crv3.call(),'0x16f179f5C344cc29672A58Ea327A26F64B941a63',10000000000e18,{'from':deployingAddress})
    initBalance = interface.IStaking(Distribution.Staking.call()).earned.call('0x9030B78A312147DbA34359d1A8819336fD054230')[1]
    Distribution.distributeFees({'from':deployingAddress})
    newBalance = interface.IStaking(Distribution.Staking.call()).earned.call('0x9030B78A312147DbA34359d1A8819336fD054230')[1]
    assert(newBalance>=initBalance) #checks if new stablecoin balance > old stablecoin balance

def eth_distribute():
    BZX = Contract.from_abi("BZX", "0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f", interface.IBZx.abi)
    assets = ['0x6B175474E89094C44Da98b954EedeAC495271d0F','0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48','0xdAC17F958D2ee523a2206206994597C13D831ec7',
            '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2']
    logic = FeeExtractAndDistribute_ETH.deploy({'from':BZX.owner()})
    proxy = Proxy_0_8.deploy(logic.address, {'from':BZX.owner()})
    BZX.setFeesController(proxy.address, {'from':BZX.owner()})
    FeeControl = Contract.from_abi('fees', proxy.address, FeeExtractAndDistribute_ETH.abi)
    FeeControl.setPaths([['0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2','0x0De05F6447ab4D22c8827449EE4bA2D5C288379B']],{'from':BZX.owner()})
    FeeControl.setBuybackSettings(30e18, {'from':BZX.owner()})
    FeeControl.setApprovals({'from':BZX.owner()})
    initBalance = interface.IERC20('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48').balanceOf('0x88DCDC47D2f83a99CF0000FDF667A468bB958a78')
    FeeControl.sweepFees(assets, {'from':BZX.owner()})
    newBalance = interface.IERC20('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48').balanceOf('0x88DCDC47D2f83a99CF0000FDF667A468bB958a78')
    assert(initBalance >= newBalance)

def poly_distribute():
    BZX = Contract.from_abi("BZX", "0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8", interface.IBZx.abi)
    assets = ['0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174','0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270','0x7ceb23fd6bc0add59e62ac25578270cff1b9f619',
            '0xc2132d05d31c914a87c6611c10748aeb04b58e8f','0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6','0x53e0bca35ec356bd5dddfebbd1fc0fd03fabad39']
    logic = FeeExtractAndDistribute_Polygon.deploy({'from':BZX.owner()})
    proxy = Proxy_0_8.deploy(logic.address, {'from':BZX.owner()})
    BZX.setFeesController(proxy.address, {'from':BZX.owner()})
    FeeControl = Contract.from_abi('fees', proxy.address, FeeExtractAndDistribute_Polygon.abi)
    FeeControl.setTreasuryWallet(BZX.address, {'from':BZX.owner()})
    FeeControl.setFeeTokens(assets, {'from':BZX.owner()})
    FeeControl.setBridge('0x88DCDC47D2f83a99CF0000FDF667A468bB958a78',{'from':BZX.owner()})
    FeeControl.setBuyBackPercentage(30e18, {'from':BZX.owner()})
    FeeControl.setBridgeApproval('0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174', {'from':BZX.owner()})
    initBalance = interface.IERC20('0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174').balanceOf('0x88DCDC47D2f83a99CF0000FDF667A468bB958a78')
    FeeControl.sweepFees({'from':BZX.owner()})
    newBalance = interface.IERC20('0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174').balanceOf('0x88DCDC47D2f83a99CF0000FDF667A468bB958a78')
    assert(initBalance >= newBalance)

def bsc_distribute():
    BZX = Contract.from_abi("BZX", "0xD154eE4982b83a87b0649E5a7DDA1514812aFE1f", interface.IBZx.abi)
    assets = ['0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c','0x2170Ed0880ac9A755fd29B2688956BD959F933F8','0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c',
            '0x55d398326f99059fF775485246999027B3197955','0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56','0xF8A0BF9cF54Bb92F17374d9e9A321E6a111a51bD']
    logic = FeeExtractAndDistribute_BSC.deploy({'from':BZX.owner()})
    proxy = Proxy_0_8.deploy(logic.address, {'from':BZX.owner()})
    BZX.setFeesController(proxy.address, {'from':BZX.owner()})
    FeeControl = Contract.from_abi('fees', proxy.address, FeeExtractAndDistribute_BSC.abi)
    FeeControl.setTreasuryWallet(BZX.address, {'from':BZX.owner()})
    FeeControl.setFeeTokens(assets, {'from':BZX.owner()})
    FeeControl.setBridge('0xdd90E5E87A2081Dcf0391920868eBc2FFB81a1aF',{'from':BZX.owner()})
    FeeControl.setBridgeApproval('0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d', {'from':BZX.owner()})
    price = Contract.from_abi('',BZX.priceFeeds(),PriceFeeds_BSC.abi)
    price.setPriceFeed(['0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d'],['0x51597f405303c4377e36123cbc172b13269ea163'],{'from':BZX.owner()})
    initBalance = interface.IERC20('0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d').balanceOf('0xdd90E5E87A2081Dcf0391920868eBc2FFB81a1aF')
    FeeControl.sweepFees({'from':BZX.owner()})
    newBalance = interface.IERC20('0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d').balanceOf('0xdd90E5E87A2081Dcf0391920868eBc2FFB81a1aF')
    assert(initBalance >= newBalance)

def arbi_distribute():
    BZX = Contract.from_abi("BZX", "0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB", interface.IBZx.abi)
    assets = ['0x82aF49447D8a07e3bd95BD0d56f35241523fBab1','0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8','0xf97f4df75117a78c1A5a0DBb814Af92458539FB4',
            '0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9','0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f','0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F']
    logic = FeeExtractAndDistribute_Arbitrum.deploy({'from':BZX.owner()})
    proxy = Proxy_0_8.deploy(logic.address, {'from':BZX.owner()})
    BZX.setFeesController(proxy.address, {'from':BZX.owner()})
    FeeControl = Contract.from_abi('fees', proxy.address, FeeExtractAndDistribute_Arbitrum.abi)
    FeeControl.setTreasuryWallet(BZX.address, {'from':BZX.owner()})
    FeeControl.setFeeTokens(assets, {'from':BZX.owner()})
    FeeControl.setBridge('0x1619DE6B6B20eD217a58d00f37B9d47C7663feca',{'from':BZX.owner()})
    FeeControl.setBridgeApproval('0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8', {'from':BZX.owner()})
    initBalance = interface.IERC20('0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8').balanceOf('0x1619DE6B6B20eD217a58d00f37B9d47C7663feca')
    FeeControl.sweepFees({'from':BZX.owner()})
    newBalance = interface.IERC20('0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8').balanceOf('0x1619DE6B6B20eD217a58d00f37B9d47C7663feca')
    assert(initBalance >= newBalance)