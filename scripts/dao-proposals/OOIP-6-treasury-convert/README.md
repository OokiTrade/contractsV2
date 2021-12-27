<br/>
<p align="center"><img src="https://bzx.network/images/logo.svg" width="256" /></p>

<div align="center">

  <a href='' style="text-decoration:none;">
    <img src='https://img.shields.io/coveralls/github/bZxNetwork/contractsV2' alt='Coverage Status' />
  </a>
  <a href='https://github.com/bZxNetwork/contractsV2/blob/master/LICENSE' style="text-decoration:none;">
    <img src='https://img.shields.io/github/license/bZxNetwork/contractsV2' alt='License' />
  </a>
  <br/>
  <a href='https://t.me/b0xNet' style="text-decoration:none;">
    <img src='https://img.shields.io/badge/chat-on%20telegram-9cf.svg?longCache=true' alt='Telegram' />
  </a>
  <a href='https://bzx.network/discord' style="text-decoration:none;">
    <img src='https://img.shields.io/discord/450115178516971531?label=Discord' alt='Discord' />
  </a>
  <a href='https://t.me/b0xNet' style="text-decoration:none;">
    <img src='https://img.shields.io/twitter/follow/bzxHQ?style=social' alt='Telegram' />
  </a>
  
</div>

# OOIP-6 DAO treasury convert

## Introduction

- convert treasury funds

## Proposal Calls

1. BZRX.approve(BZRX_CONVERTER, amount)
2. BZRX_CONVERTER.convert(TIMELOCK, BZRX.balanceOf(TIMELOCK), {'from': TIMELOCK})
3. BZX.setFeeController(address(0))
4. BZX.setBorrowingFeePercent(0)
5. BZX.setLoanPool([iOOKI], [OOKI])
6. BZX.setLiquidationIncentivePercent(...) for iOOKI, this doesn't enable it for trading nor being as collateral



## Forum Discussion



## Snapshot Vote




