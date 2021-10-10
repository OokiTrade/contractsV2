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

# OOIP-3 DAO upgrade smart contract to support batch operations, add support for voting delegation, maintenance tasks

## Introduction

- To optimise gas costs multiple batch operations needs to be supported.
- In order improve user participation vote delegation is going to be enabled.
- `quorumVotes` is going to be lowered
- `proposalMaxOperations` is going to be increased
- Disable old protocol CHI module for swaps 
- disable LEND pool. 
- As part of the B.Protocol proposal send 250k BZRX to them
- As part of token migration create new iOOKI token

## Proposal Calls

1. upgrade DAO implementation
2. upgrade STAKING implementation
3. BZX.setTargets(...) to disable CHI modules
4. BZX.setLoanPool(...) to disable LEND pool
5. BZRX.transferFrom(Timelock, 0x2a599cEba64CAb8C88549c2c7314ea02A161fC70) 250k transfer for B.Protocol to guardian multisig, also allocate funds for BGOV PGOV buyout
6. BZX.replaceContract to deploy ProtocolPausableGuardian module
7. Upgrade staking set approvals
<!-- 7. bzx.setLoanPool([iOOKI], [OOKI])
8. bzx.setSupportedTokens([OOKI], [True])
9. bzx.setLiquidationIncentivePercent(...) -->



## Forum Discussion

[here](https://forum.bzx.network/t/integrate-bzx-fulcrum-with-b-protocol-v2-over-polygon/402)

## Snapshot Vote

[here](https://snapshot.org/#/bzx.eth/proposal/Qmd8xTvrhVjKq5fcyuPqyehk8GXMQQFHR4qbUSvYuZ4Br8)


