pragma solidity 0.5.17;

import "../../governance/PausableGuardian.sol";
import "../../../interfaces/IToken.sol";
import "../../../interfaces/IBZx.sol";
import "./FactoryLoanToken.sol";
import "@openzeppelin-2.5.0/token/ERC20/ERC20Detailed.sol";
import "../../interfaces/ISignatureHelper.sol";

contract LoanTokenFactory is PausableGuardian {
    IBZx public constant PROTOCOL = IBZx(address(0));
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

    function convertITokenToWhitelisted(address payable iTokenAddress, address _rateHelper, uint256 flashLoanFeePercent)
        external
        onlyOwner
    {
        FactoryLoanToken f = FactoryLoanToken(iTokenAddress);
        f.setTarget(whitelistedITokenTarget);
        f.setFactory(address(0));
        IToken(iTokenAddress).setDemandCurve(_rateHelper);
        IToken(iTokenAddress).updateFlashBorrowFeePercent(flashLoanFeePercent);
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