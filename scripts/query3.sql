WITH PREPARE AS
  (SELECT topic1,
          topic2,
          topic3,
          topic4,
          tx_hash,
          block_hash,
          block_number,
          (EXTRACT(EPOCH
                   FROM block_time))::bigint AS block_time, --   block_time as block_time_as_date,
 INDEX,
 tx_index,
 SUBSTRING(DATA, 1, 32) AS data1,
 SUBSTRING(DATA, 33, 32) AS data2,
 SUBSTRING(DATA, 65, 32) AS data3,
 SUBSTRING(DATA, 97, 32) AS data4,
 SUBSTRING(DATA, 129, 32) AS data5,
 SUBSTRING(DATA, 161, 32) AS data6,
 SUBSTRING(DATA, 193, 32) AS data7,
 SUBSTRING(DATA, 225, 32) AS data8,
 SUBSTRING(DATA, 257, 32) AS data9 --  10900435 AS current_block_number,
--  1600620800 AS current_block_time

   FROM ethereum."logs"
   WHERE contract_address ='\xd8ee69652e4e4838f2531732a46d1f7f584f0b7f' 
   AND block_number < 11610119

     AND (topic1 = '\x7bd8cbb7ba34b33004f3deda0fd36c92fc0360acbd97843360037b467a538f90' -- kessak(Borrow(address,address,bytes32,address,address,uint256,uint256,uint256,uint256,uint256,uint256))

          OR topic1 = '\xf640c1cfe1a912a0b0152b5a542e5c2403142eed75b06cde526cee54b1580e5c' -- kessak(Trade(address,address,bytes32,address,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256))

          OR topic1 = '\x6349c1a02ec126f7f4fc6e6837e1859006e90e9901635c442d29271e77b96fb6' -- kessak(CloseWithDeposit(address,address,bytes32,address,address,address,uint256,uint256,uint256,uint256))

          OR topic1 = '\x2ed7b29b4ca95cf3bb9a44f703872a66e6aa5e8f07b675fa9a5c124a1e5d7352' -- kessak(CloseWithSwap(address,address,bytes32,address,address,address,uint256,uint256,uint256,uint256))

          OR topic1 = '\x46fa03303782eb2f686515f6c0100f9a62dabe587b0d3f5a4fc0c822d6e532d3' -- kessak(Liquidate(address,address,bytes32,address,address,address,uint256,uint256,uint256,uint256))

          OR topic1 = '\x21e656d09cbbafac02fd00fc98d308d0df53e46fa0a7b4358eca09302afc2e58' -- kessak(Rollover(address,address,bytes32,address,address,address,uint256,uint256,uint256,uint256))
 )--  AND tx_hash = '\x7f15c7cd8ecd4268f68eff35a6269d8ac12292d2e831a2256c78b60958871f2e'  -- borrow example
-- and tx_hash = '\xcf1abeddf4ca4b9ab7d1b351261eef76c3ba4a44243f97f03fd98640fd45bb10' -- trade example
-- and tx_hash = '\1221a0dc97a83a116fabbc4663392f6d9725de756831fc0498bc91303a7561e8' -- close with deposit example
 --   LIMIT 5
 ) , populateEvents AS
  (SELECT topic2 AS userAddress,
          topic3 AS lender,
          data1 AS loanToken,
          data3 AS newPrincipal,
          block_number,
          block_time,
          INDEX,
          'borrow' AS paymentType
   FROM PREPARE
   WHERE topic1 = '\x7bd8cbb7ba34b33004f3deda0fd36c92fc0360acbd97843360037b467a538f90' -- borrow

   UNION ALL SELECT topic2 AS userAddress,
                    topic3 AS lender,
                    data2 AS loanToken,
                    data4 AS newPrincipal,
                    block_number,
                    block_time,
                    INDEX,
                    'trade' AS paymentType
   FROM PREPARE
   WHERE topic1 = '\xf640c1cfe1a912a0b0152b5a542e5c2403142eed75b06cde526cee54b1580e5c' -- trade

   UNION ALL SELECT topic2 AS userAddress,
                    topic3 AS lender,
                    data2 AS loanToken,
                    data4 AS newPrincipal,
                    block_number,
                    block_time,
                    INDEX,
                    'closewithdeposit' AS paymentType
   FROM PREPARE
   WHERE topic1 = '\x6349c1a02ec126f7f4fc6e6837e1859006e90e9901635c442d29271e77b96fb6' -- close with deposit

   UNION ALL SELECT topic2 AS userAddress,
                    topic3 AS lender,
                    data2 AS loanToken,
                    data5 AS newPrincipal,
                    block_number,
                    block_time,
                    INDEX,
                    'closewithswap' AS paymentType
   FROM PREPARE
   WHERE topic1 = '\x2ed7b29b4ca95cf3bb9a44f703872a66e6aa5e8f07b675fa9a5c124a1e5d7352' -- close with swap

   UNION ALL SELECT topic2 AS userAddress,
                    topic3 AS lender,
                    data2 AS loanToken,
                    data4 AS newPrincipal,
                    block_number,
                    block_time,
                    INDEX,
                    'liquidate' AS paymentType
   FROM PREPARE
   WHERE topic1 = '\x46fa03303782eb2f686515f6c0100f9a62dabe587b0d3f5a4fc0c822d6e532d3' -- Liquidate
 --  we have no rollovers yet. I dodn't know how to count them as + principal or - principal
 
--   UNION ALL SELECT topic2 AS userAddress, 
--                     topic3 AS lender, 
--                     data2 AS loanToken, 
--                     data4 AS newPrincipal, 
--                     block_number, 
--                     block_time, 
--                     INDEX, 
--                     'rollover' AS paymentType
--   FROM PREPARE 
--   WHERE topic1 = '\x21e656d09cbbafac02fd00fc98d308d0df53e46fa0a7b4358eca09302afc2e58' -- Rollover
 ), 
     populateTokenSymbol AS 
  (SELECT CASE 
              WHEN CONCAT('0x', ENCODE(SUBSTRING(loanToken, 13, 20), 'hex')) = LOWER('0x6b175474e89094c44da98b954eedeac495271d0f') THEN 'DAI' 
              WHEN CONCAT('0x', ENCODE(SUBSTRING(loanToken, 13, 20), 'hex')) = LOWER('0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2') THEN 'ETH' 
              WHEN CONCAT('0x', ENCODE(SUBSTRING(loanToken, 13, 20), 'hex')) = LOWER('0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48') THEN 'USDC' 
              WHEN CONCAT('0x', ENCODE(SUBSTRING(loanToken, 13, 20), 'hex')) = LOWER('0x2260fac5e5542a773aa44fbcfedf7c193bc2c599') THEN 'WBTC' 
              WHEN CONCAT('0x', ENCODE(SUBSTRING(loanToken, 13, 20), 'hex')) = LOWER('0x80fB784B7eD66730e8b1DBd9820aFD29931aab03') THEN 'LEND' 
              WHEN CONCAT('0x', ENCODE(SUBSTRING(loanToken, 13, 20), 'hex')) = LOWER('0xdd974d5c2e2928dea5f71b9825b8b646686bd200') THEN 'KNC' 
              WHEN CONCAT('0x', ENCODE(SUBSTRING(loanToken, 13, 20), 'hex')) = LOWER('0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2') THEN 'MKR' 
              WHEN CONCAT('0x', ENCODE(SUBSTRING(loanToken, 13, 20), 'hex')) = LOWER('0x56d811088235F11C8920698a204A5010a788f4b3') THEN 'BZRX' 
              WHEN CONCAT('0x', ENCODE(SUBSTRING(loanToken, 13, 20), 'hex')) = LOWER('0x514910771AF9Ca656af840dff83E8264EcF986CA') THEN 'LINK' 
              WHEN CONCAT('0x', ENCODE(SUBSTRING(loanToken, 13, 20), 'hex')) = LOWER('0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e') THEN 'YFI' 
              WHEN CONCAT('0x', ENCODE(SUBSTRING(loanToken, 13, 20), 'hex')) = LOWER('0xdac17f958d2ee523a2206206994597c13d831ec7') THEN 'USDT' 
              WHEN CONCAT('0x', ENCODE(SUBSTRING(loanToken, 13, 20), 'hex')) = LOWER('0xb72b31907c1c95f3650b64b2469e08edacee5e8f') THEN 'vBZRX' 
              WHEN CONCAT('0x', ENCODE(SUBSTRING(loanToken, 13, 20), 'hex')) = LOWER('0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984') THEN 'UNI' 
              WHEN CONCAT('0x', ENCODE(SUBSTRING(loanToken, 13, 20), 'hex')) = LOWER('0x7fc66500c84a76ad7e9c93437bfc5ac33e2ddae9') THEN 'AAVE'
              WHEN CONCAT('0x', ENCODE(SUBSTRING(loanToken, 13, 20), 'hex')) = LOWER('0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD') THEN 'LRC'
              
          END AS tokenSymbol, 
          *
   FROM populateEvents), 
     populateNewPrincipalDecimal AS 
  (SELECT *, 
          CASE 
              WHEN (tokensymbol = 'USDC'
                    OR tokensymbol='USDT') THEN (bytea2numericpy(newPrincipal)/power(10, 6))::numeric 
              WHEN (tokensymbol = 'WBTC') THEN (bytea2numericpy(newPrincipal)/power(10, 8))::numeric 
              ELSE (bytea2numericpy(newPrincipal)/power(10, 18))::numeric 
          END AS newPrincipalDecimal
   FROM populateTokenSymbol)
SELECT -- count(1)
 userAddress, 
 loanToken, 
 tokenSymbol, 
 block_time, 
 INDEX, 
 paymentType, 
 newPrincipalDecimal 
FROM populateNewPrincipalDecimal 
-- WHERE lower(CONCAT('0x', ENCODE(SUBSTRING(useraddress, 13, 20), 'hex'))) = lower('0xE487A866b0f6b1B663b4566Ff7e998Af6116fbA9')
ORDER BY userAddress,
        --  loanToken,
         block_time
        --  INDEX;

