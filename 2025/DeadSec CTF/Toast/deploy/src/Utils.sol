// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract AuthenticatedProxy {
    enum HowToCall { Call, Delegate }
}

library SaleKindInterface {
    enum Side { Buy, Sell }
    enum SaleKind { FixedPrice }
}

enum FeeMethod { NoFee }

struct Order {
    address exchange;
    address maker;
    uint256 salt;
    address taker;
    SaleKindInterface.Side side;
    SaleKindInterface.SaleKind saleKind;
    address target;
    AuthenticatedProxy.HowToCall howToCall;
    bytes calldata_;
    address staticTarget;
    address paymentToken;
    uint256 basePrice;
    uint256 expirationTime;
    FeeMethod feeMethod;
    bytes sig;
}

struct SimpleOrder {
    address exchange;
    address maker;
    uint256 salt;
    address taker;
    uint8 feeMethod;
    uint8 side;
    uint8 saleKind;
    address target;
    uint8 howToCall;
    bytes calldata_;
    address staticTarget;
    address paymentToken;
    uint256 basePrice;
    uint256 expirationTime;
}

library util {
    function usingSimpleOrder(function (SimpleOrder calldata) internal returns(bytes32) fnIn) internal pure returns(function (Order calldata) internal returns(bytes32) fnOut) {
        assembly ("memory-safe") {
            fnOut := fnIn
        }
    }

    function asRawPtr(Order calldata order) internal pure returns (uint256 rawOrderPtr) {
        assembly {
            rawOrderPtr := order
        }
    }

    function asRawPtr(SimpleOrder calldata order) internal pure returns (uint256 rawOrderPtr) {
        assembly {
            rawOrderPtr := order
        }
    }
}