// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import "src/Utils.sol";

contract C0{
    function hashOrder(uint256 calldataPointer, uint256 offset) internal pure virtual returns (bytes32 hash) {
        assembly ("memory-safe") {
            calldatacopy(offset, calldataPointer, 0x20)
            offset := add(offset, 0x20)
            calldataPointer := add(calldataPointer, 0x20)
        }
    }
}

contract C1 is C0{
    function hashOrder(uint256 calldataPointer, uint256 offset) internal pure virtual override returns (bytes32 hash) {
        assembly ("memory-safe") {
            calldatacopy(offset, calldataPointer, 0x20)
            offset := add(offset, 0x20)
            calldataPointer := add(calldataPointer, 0x20)
        }
        
        super.hashOrder(calldataPointer, offset);
    }
}

contract C2 is C0{
    function hashOrder(uint256 calldataPointer, uint256 offset) internal pure virtual override returns (bytes32 hash) {
        assembly ("memory-safe") {
            calldatacopy(offset, calldataPointer, 0x20)
            offset := add(offset, 0x20)
            calldataPointer := add(calldataPointer, 0x20)
        }
        
        super.hashOrder(calldataPointer, offset);
    }
}

contract C3 is C1 {
    function hashOrder(uint256 calldataPointer, uint256 offset) internal pure virtual override returns (bytes32 hash) {
        assembly ("memory-safe") {
            calldatacopy(offset, calldataPointer, 0x20)
            offset := add(offset, 0x20)
            calldataPointer := add(calldataPointer, 0x20)
        }
        
        super.hashOrder(calldataPointer, offset);
    }
}

contract C4 is C1, C2 {
    function hashOrder(uint256 calldataPointer, uint256 offset) internal pure virtual override(C1, C2) returns (bytes32 hash) {
        assembly ("memory-safe") {
            calldatacopy(offset, calldataPointer, 0x20)
            offset := add(offset, 0x20)
            calldataPointer := add(calldataPointer, 0x20)
        }
        
        super.hashOrder(calldataPointer, offset);
    }
}

contract C5 is C2{
    function hashOrder(uint256 calldataPointer, uint256 offset) internal pure virtual override returns (bytes32 hash) {
        assembly ("memory-safe") {
            calldatacopy(offset, calldataPointer, 0x20)
            offset := add(offset, 0x20)
            calldataPointer := add(calldataPointer, 0x20)
        }
        
        super.hashOrder(calldataPointer, offset);
    }
}

contract C6 is C3, C4 {
    function hashOrder(uint256 calldataPointer, uint256 offset) internal pure virtual override(C3, C4) returns (bytes32 hash) {
        assembly ("memory-safe") {
            let headerSize := sub(calldataPointer, 0x100)
            let ptr := add(headerSize, calldataload(calldataPointer))
            let size := calldataload(ptr)
            calldatacopy(offset, add(ptr, 0x20), size)
            mstore(offset, keccak256(offset, size))

            offset := add(offset, 0x20)
            calldataPointer := add(calldataPointer, 0x20)
        }
        
        super.hashOrder(calldataPointer, offset);
    }
}

contract C7 is C4, C5 {
    function hashOrder(uint256 calldataPointer, uint256 offset) internal pure virtual override(C4, C5) returns (bytes32 hash) {
        assembly ("memory-safe") {
            calldatacopy(offset, calldataPointer, 0x20)
            offset := add(offset, 0x20)
            calldataPointer := add(calldataPointer, 0x20)
        }
        
        super.hashOrder(calldataPointer, offset);
    }
}

contract C8 is C6 {    
    function hashOrder(uint256 calldataPointer, uint256 offset) internal pure virtual override returns (bytes32 hash) {
        assembly ("memory-safe") {
            calldatacopy(offset, calldataPointer, 0x20)
            offset := add(offset, 0x20)
            calldataPointer := add(calldataPointer, 0x20)
        }
        
        super.hashOrder(calldataPointer, offset);
    }
}

contract C9 is C6, C7 {
    function hashOrder(uint256 calldataPointer, uint256 offset) internal pure virtual override(C6, C7) returns (bytes32 hash) {
        assembly ("memory-safe") {
            calldatacopy(offset, calldataPointer, 0x20)
            offset := add(offset, 0x20)
            calldataPointer := add(calldataPointer, 0x20)
        }
        
        super.hashOrder(calldataPointer, offset);
    }
}

contract C10 is C7{
    function hashOrder(uint256 calldataPointer, uint256 offset) internal pure virtual override returns (bytes32 hash) {
        assembly ("memory-safe") {
            calldatacopy(offset, calldataPointer, 0x20)
            offset := add(offset, 0x20)
            calldataPointer := add(calldataPointer, 0x20)
        }

        super.hashOrder(calldataPointer, offset);
    }
}

contract C11 is C8, C9 {
    function hashOrder(uint256 calldataPointer, uint256 offset) internal pure virtual override(C8, C9) returns (bytes32 hash) {
        assembly ("memory-safe") {
            calldatacopy(offset, calldataPointer, 0x20)
            offset := add(offset, 0x20)
            calldataPointer := add(calldataPointer, 0x20)
        }

        super.hashOrder(calldataPointer, offset);
    }
}

contract C12 is C9, C10 {
    function hashOrder(uint256 calldataPointer, uint256 offset) internal pure virtual override(C9, C10) returns (bytes32 hash) {
        assembly ("memory-safe") {
            calldatacopy(offset, calldataPointer, 0x20)
            offset := add(offset, 0x20)
            calldataPointer := add(calldataPointer, 0x20)
        }

        super.hashOrder(calldataPointer, offset);
    }
}

contract C13 is C11, C12 {
    // keccak256("SimpleOrder(address exchange,address maker,uint256 salt,address taker,uint8 feeMethod,uint8 side,uint8 saleKind,address target,uint8 howToCall,bytes calldata_,address staticTarget,address paymentToken,uint256 basePrice,uint256 expirationTime)")
    bytes32 internal immutable TYPEHASH = 0xca2b31eece9789f8640037795ba5e3065ba8d82ef095c0f8c0f4310a0d1f96ea;

    function hashOrder(uint256 calldataPointer, uint256 offset) internal pure virtual override(C11, C12) returns (bytes32 hash) {
        uint256 m;
        bytes32 typeHash = TYPEHASH;
        assembly ("memory-safe") {
            m := mload(0x40) // Retrieve the free memory pointer.
            mstore(offset, typeHash)
            offset := add(offset, 0x20)

            calldatacopy(offset, calldataPointer, 0x20)
            offset := add(offset, 0x20)
            calldataPointer := add(calldataPointer, 0x20)
        }

        super.hashOrder(calldataPointer, offset);

        assembly ("memory-safe") {
            hash := keccak256(0, 0x1e0)
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }
}

contract Exchange is C13 {
    using util for Order;
    using util for SimpleOrder;
    using util for function (SimpleOrder calldata) internal returns (bytes32);

    error InvalidSignature();

    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 internal immutable DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    function ordersCanMatch(Order calldata buy, Order calldata sell) internal pure returns (bool) {
        return (
            (buy.side == SaleKindInterface.Side.Buy && sell.side == SaleKindInterface.Side.Sell) &&
            (buy.feeMethod == sell.feeMethod) &&
            (buy.paymentToken == sell.paymentToken) &&
            (sell.taker == address(0) || sell.taker == buy.maker) &&
            (buy.taker == address(0) || buy.taker == sell.maker) &&
            (buy.target == sell.target) &&
            (buy.howToCall == sell.howToCall)
        );
    }

    function generateDigest(SimpleOrder calldata order) public returns (bytes32 digest) {
        bytes32 hash = hashOrder(order.asRawPtr(), 0x0);

        bytes32 domainHash = keccak256(abi.encode(
            DOMAIN_TYPEHASH,
            keccak256("Toast"),
            keccak256("0"),
            block.chainid,
            address(this)
        ));

        digest = keccak256(
            abi.encodePacked(
                hex'1901',
                domainHash,
                hash
            )
        );
    }

    function atomicMatch(Order calldata buy, Order calldata sell) external {
        address[] memory recipients;

        if(!SignatureChecker.isValidSignatureNow(sell.maker, generateDigest.usingSimpleOrder()(sell), sell.sig)) {
            revert InvalidSignature();
        }
        if(!SignatureChecker.isValidSignatureNow(buy.maker, generateDigest.usingSimpleOrder()(buy), buy.sig)) {
            revert InvalidSignature();
        }

        require(ordersCanMatch(buy, sell));

        uint256 len;
        bytes memory calldata_ = buy.calldata_;

        assembly ("memory-safe") {
            let ptr := calldata_
            let offset := mload(add(ptr, 0x20))
            len := mload(add(add(ptr, 0x20), offset))
        }

        if(len < 10) 
            recipients = abi.decode(calldata_, (address[]));

        bool success;

        if(sell.howToCall == AuthenticatedProxy.HowToCall.Call) {
            (success, ) = address(sell.target).call(abi.encodeWithSignature('pwn(address[],address,address,uint256)', recipients, buy.maker, sell.maker, sell.basePrice));
        } else if(sell.howToCall == AuthenticatedProxy.HowToCall.Delegate) {
            (success, ) = address(sell.target).delegatecall(abi.encodeWithSignature('pwn(address[],address,address,uint256)', recipients, buy.maker, sell.maker, sell.basePrice));
        }
        
        require(success);
    }
}