
import { ChainId, Symbiosis, Token, TokenAmount } from 'symbiosis-js-sdk'
import { BytesLike, ethers } from 'ethers'
import { Contract } from '@ethersproject/contracts'
import { MaxUint256 } from '@ethersproject/constants'

const approveAbi = [
    {
        constant: false,
        inputs: [
            { name: '_spender', type: 'address' },
            { name: '_value', type: 'uint256' },
        ],
        name: 'approve',
        outputs: [{ name: '', type: 'bool' }],
        payable: false,
        stateMutability: 'nonpayable',
        type: 'function',
    },
]


const privateKey = ''

const wallet = new ethers.Wallet(privateKey as BytesLike)


const symbiosis = new Symbiosis('mainnet', 'sdk-example-app')
const provider = symbiosis.getProvider(ChainId.BSC_MAINNET)
const signer = wallet.connect(provider)

const tokenIn = new Token({
    chainId: ChainId.BSC_MAINNET,
    address: '0x55d398326f99059fF775485246999027B3197955',
    name: 'USDT',
    symbol: 'USDT',
    decimals: 18,
})

const iTokenOut = new Token({
    chainId: ChainId.MATIC_MAINNET,
    address: '0x5BFAC8a40782398fb662A69bac8a89e6EDc574b1',
    name: 'iUSDT',
    symbol: 'iUSDT',
    decimals: 6,
})

const tokenAmountIn = new TokenAmount(
    tokenIn,
    '15000000000000000000' // 15 USDT
)

async function zapOkkiLendErc20() {
    try {

        const zapping = symbiosis.newZappingOoki()

        // Calculates fee for zapping between chains and transactionRequest
        console.log('Calculating zap...')
        const { transactionRequest, fee, tokenAmountOut, route, priceImpact, approveTo } = await zapping.exactIn(
            tokenAmountIn, // TokenAmount object
            iTokenOut.address, // iToken address
            iTokenOut.chainId, // chain id
            wallet.address, // from account address
            wallet.address, // to account address
            wallet.address, // account who can revert stucked transaction
            300, // 3% slippage
            Date.now() + 20 * 60, // 20 minutes deadline
            true
        )

        console.log({
            fee: fee.toSignificant(),
            tokenAmountOut: tokenAmountOut.toSignificant(),
            route: route.map((i) => i.symbol).join(' -> '),
            priceImpact: priceImpact.toSignificant(),
            approveTo,
        })

        if (!tokenAmountIn.token.isNative) {
            console.log('Approving...')
            const tokenContract = new Contract(tokenAmountIn.token.address, JSON.stringify(approveAbi), signer)
            const approveResponse = await tokenContract.approve(approveTo, MaxUint256)
            console.log('Approved', approveResponse.hash)

            const approveReceipt = await approveResponse.wait(1)
            console.log('Approve mined', approveReceipt.transactionHash)
        }

        // Send transaction to chain
        const transactionResponse = await signer.sendTransaction(transactionRequest)
        console.log('Transaction sent', transactionResponse.hash)

        // Wait for transaction to be mined
        const receipt = await transactionResponse.wait(1)
        console.log('Transaction mined', receipt.transactionHash)

        // Wait for transaction to be completed on recipient chain
        const log = await zapping.waitForComplete(receipt)
        console.log('Cross-chain zap completed', log.transactionHash)

    } catch (e) {
        console.error(e)
    }
}

console.log('>>>')
zapOkkiLendErc20().then(() => {
    console.log('<<<')
})
