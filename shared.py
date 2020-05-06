#!/usr/bin/python3

def Constants():
    return {
        "ZERO_ADDRESS": "0x0000000000000000000000000000000000000000",
        "ONE_ADDRESS": "0x0000000000000000000000000000000000000001",
        "MAX_UINT": "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    }

def FuncSigs():
    return {
        "ProtocolSettings": {
            "setCoreParams": "setCoreParams(address,address,address,uint256)",
            "setProtocolManagers": "setProtocolManagers(address[],bool[])",
        },
        "LoanSettings": {
            "setupLoanParams": "setupLoanParams((bytes32,bool,address,address,address,uint256,uint256,uint256))",
            "setupLoanParams2": "setupLoanParams((bytes32,bool,address,address,address,uint256,uint256,uint256)[])",
            "disableLoanParams": "disableLoanParams(bytes32[])",
            "getLoanParams": "getLoanParams(bytes32)",
            "getLoanParams2": "getLoanParams(bytes32[])",
            "setupOrder": "setupOrder((bytes32,bool,address,address,address,uint256,uint256,uint256),uint256,uint256,uint256,uint256,uint256,bool)",
            "setupOrder2": "setupOrder(bytes32,uint256,uint256,uint256,uint256,uint256,bool)",
            "depositToOrder": "depositToOrder(bytes32,uint256,bool)",
            "withdrawFromOrder": "withdrawFromOrder(bytes32,uint256,bool)",
        },
        "LoanOpenings": {
            "borrow": "borrow(bytes32,bytes32,uint256,uint256,address,address,address)",
            #"openLoanFromPool": "openLoanFromPool(bytes32,bytes32,address[4],uint256[6],bytes)",
            "setDelegatedManager": "setDelegatedManager(bytes32,address,bool)",
            "getRequiredCollateral": "getRequiredCollateral(address,address,address,uint256,uint256,bool)",
            "getBorrowAmount": "getBorrowAmount(address,address,uint256,uint256)",
        },
    }
