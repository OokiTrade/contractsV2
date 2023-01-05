<br/>
<p align="center"><img src="https://user-images.githubusercontent.com/1526150/185404709-25820340-18e6-4dd6-b0f8-05a1b91ba803.png" width="256" /></p>

<div align="center">

  <!-- <a href='' style="text-decoration:none;">
    <img src='https://img.shields.io/coveralls/github/OokiTrade/contractsV2' alt='Coverage Status' />
  </a> -->
  <a href='https://github.com/OokiTrade/contractsV2/blob/development/LICENSE' style="text-decoration:none;">
    <img src='https://img.shields.io/github/license/OokiTrade/contractsV2' alt='License' />
  </a>
  <a href='https://docs.openzeppelin.com/' style="text-decoration:none;">
    <img src='https://img.shields.io/badge/built%20with-OpenZeppelin-3677FF' alt='OpenZeppelin' />
  </a>
  <br/>
  <a href='https://t.me/OokiTrade' style="text-decoration:none;">
    <img src='https://img.shields.io/badge/chat-on%20telegram-9cf.svg?longCache=true' alt='Telegram' />
  </a>
  <a href='https://discord.gg/4wPVA6a' style="text-decoration:none;">
    <img src='https://img.shields.io/discord/450115178516971531?label=Discord' alt='Discord' />
  </a>
  <a href='https://t.me/OokiTrade' style="text-decoration:none;">
    <img src='https://img.shields.io/twitter/follow/OokiTrade?style=social' alt='Telegram' />
  </a>
  
</div>

# OOKI Smart Contracts

## Dependencies

* [python3](https://www.python.org/downloads/release/python-368/) version 3.6 or greater, python3-dev
* [ganache-cli](https://github.com/trufflesuite/ganache-cli) - tested with version [6.12.2](https://github.com/trufflesuite/ganache-cli/releases/tag/v6.12.2)
* [brownie](https://github.com/eth-brownie/brownie/) version 1.19.1 or greater

## Documentation and Support

## Testing

To run the tests, first install the developer dependencies:

```bash
pip install -r requirements.txt
```

also install brownie dependencies
```
make sure to add dependencies to compile:

```
brownie pm install openzeppelin/openzeppelin-contracts@4.8.0
brownie pm install openzeppelin/openzeppelin-contracts-upgradeable@4.8.0
brownie pm install openzeppelin/openzeppelin-contracts@3.4.2
brownie pm install openzeppelin/openzeppelin-contracts@2.5.1
brownie pm install uniswap/v2-core@1.0.1
brownie pm install uniswap/v3-core@1.0.0
brownie pm install uniswap/v3-periphery@1.3.0
brownie pm install celer-network/sgn-v2-contracts@0.2.0
brownie pm install paulrberg/prb-math@2.4.1
```

cloning without version - otherwise uniswap is not compiling properly due to inter dependency between core and periphery
```
brownie pm clone uniswap/v2-core@1.0.1 ~/.brownie/packages/uniswap/v2-core
brownie pm clone uniswap/v3-core@1.0.0 ~/.brownie/packages/uniswap/v3-core
brownie pm clone uniswap/v3-periphery@1.3.0 ~/.brownie/packages/uniswap/v3-periphery
```

Run the all tests with:

```bash
brownie test
```

## License

This project is licensed under the [Apache License, Version 2.0](LICENSE).
