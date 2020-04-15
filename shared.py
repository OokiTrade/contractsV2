#!/usr/bin/python3

def Constants():
    return {
        "ZERO_ADDRESS": "0x0000000000000000000000000000000000000000",
        "ONE_ADDRESS": "0x0000000000000000000000000000000000000001",
    }

def FuncSigs():
    return {
        "ProtocolSettings": {
            ## ProtocolSettings
            "setCoreParams": "setCoreParams(address,address,address)",
            "setProtocolManagers": "setProtocolManagers(address[],bool[])",
        },
        "LoanSettings": {
            "setupLoanParams": "setupLoanParams((bytes32,bool,address,address,address,uint256,uint256,uint256))",
            "setupLoanParams2": "setupLoanParams((bytes32,bool,address,address,address,uint256,uint256,uint256)[])",
            "disableLoanParams": "disableLoanParams(bytes32[])",
            #"getLoanParams": "getLoanParams(bytes32[])",
            "getLoanParams": "getLoanParams(bytes32)",
            "setupOrder": "setupOrder((bytes32,bool,address,address,address,uint256,uint256,uint256),uint256,uint256,uint256,bool)",
            "setupOrder2": "setupOrder(uint256,uint256,uint256,uint256,bool)",
        },
        "LoanOpenings": {
            #"openLoanFromPool": "openLoanFromPool(bytes32,bytes32,address[4],uint256[6],bytes)",
            #"setDelegatedManager": "setDelegatedManager(bytes32,address,bool)",
            #"getRequiredCollateral": "getRequiredCollateral(address,address,address,uint256,uint256)",
            #"getBorrowAmount": "getBorrowAmount(address,address,uint256,uint256)",
        },
    }
