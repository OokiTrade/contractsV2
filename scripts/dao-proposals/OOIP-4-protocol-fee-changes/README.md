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

# OOIP-4 DAO upgrades smart contracts to introduce fees on flash loans and change borrowing fees

## Introduction

- To introduce fees on flash loans, flash loan fee rate needs to be added to loan token logic
- For fees to paid, a function for paying fees needs to be added to Protocol contract
- `borrowingFeePercent` is going to be set to 0
- `flashBorrowFeePercent` is going to be introduced and initialized
- add support for OOKI
- adjust liquidiation incentives

## Proposal Calls

1. upgrade LOANTOKEN implementation
2. upgrade PROTOCOL logic
3. bzx.setLoanPool([iOOKI], [OOKI])
4. bzx.setSupportedTokens([OOKI], [True])
5. bzx.setLiquidationIncentivePercent(...)



## Forum Discussion

[here](https://forum.bzx.network/t/eliminating-origination-fees-and-changes-to-the-lend-borrow-market/443)

## Snapshot Vote

[here](https://snapshot.org/#/bzx.eth/proposal/QmVQgj3xyGR3ieHAGdAgomt59KjETJYvyFpm54f2u4kZQW)


