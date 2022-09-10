pragma solidity 0.5.17;

import "../../governance/PausableGuardian.sol";
import "../../../interfaces/IToken.sol";
import "../../../interfaces/IBZx.sol";
import "./FactoryLoanToken.sol";
import "@openzeppelin-2.5.0/token/ERC20/ERC20Detailed.sol";
import "../../interfaces/ISignatureHelper.sol";

contract LoanTokenFactory is PausableGuardian {
    IBZx public constant PROTOCOL = IBZx(0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f); // mainnet
    // IBZx public constant PROTOCOL = IBZx(0xD154eE4982b83a87b0649E5a7DDA1514812aFE1f); // bsc
    // IBZx public constant PROTOCOL = IBZx(0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8); // polygon
    // IBZx public constant PROTOCOL = IBZx(0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB); // arbitrum
    // IBZx public constant PROTOCOL = IBZx(0xAcedbFd5Bc1fb0dDC948579d4195616c05E74Fd1); // optimism
    address public constant SIG_HELPER = address(0);
    address public rateHelper;
    uint256 flashLoanFeePercent;
    address public target;
    address public whitelistedITokenTarget;

    function addNewToken(
        address loanTokenAddress)
        external
    {
        address iToken = _createLoanToken(loanTokenAddress);
        address[] memory pools = new address[](1);
        pools[0] = iToken;
        address[] memory assets = new address[](1);
        assets[0] = loanTokenAddress;
        PROTOCOL.setLoanPool(pools, assets);
        address[] memory addrs = new address[](1);
        addrs[0] = loanTokenAddress;
        bool[] memory toggles = new bool[](1);
        toggles[0] = true;
        PROTOCOL.setSupportedTokens(addrs, toggles, true);
    }
    function _createLoanToken(
        address loanTokenAddress)
        internal
        pausable
        returns (address)
    {
        address newLoanToken = address(new FactoryLoanToken());
        string memory symbol = ERC20Detailed(loanTokenAddress).symbol();
        string memory name = string(abi.encodePacked("Ooki ", symbol, " iToken"));
        symbol = string(abi.encodePacked("i", symbol));
        IToken(newLoanToken).initialize(loanTokenAddress, name, symbol);
        return newLoanToken;
    }

    function getRateHelper()
        external
        view
        returns (address)
    {
        return rateHelper;
    }

    function getFlashLoanFeePercent()
        external
        view
        returns (uint256)
    {
        return flashLoanFeePercent;
    }

    function getTarget()
        external
        view
        returns (address)
    {
        return target;
    }

    function setRateHelper(address helper)
        external
        onlyGuardian
    {
        rateHelper = helper;
    }

    function setFlashLoanFeePercent(uint256 percent)
        external
        onlyOwner
    {
        flashLoanFeePercent = percent;
    }

    function setTarget(address newTarget)
        external
        onlyOwner
    {
        target = newTarget;
    }

    function setWhitelistTarget(address newTarget)
        external
        onlyOwner
    {
        whitelistedITokenTarget = newTarget;
    }

    function convertITokenToWhitelisted(address payable iTokenAddress, address _rateHelper, uint256 flashLoanFee)
        external
        onlyOwner
    {
        FactoryLoanToken f = FactoryLoanToken(iTokenAddress);
        f.setTarget(whitelistedITokenTarget);
        f.setFactory(address(0));
        IToken(iTokenAddress).setDemandCurve(_rateHelper);
        IToken(iTokenAddress).updateFlashBorrowFeePercent(flashLoanFee);
        f.transferOwnership(owner());
        
    }

    function isPaused(bytes calldata data)
        external
        view
        returns (bool)
    {
        return _isPaused(ISignatureHelper(SIG_HELPER).getSig(data)); //slice to get signature
    }
}