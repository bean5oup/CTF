// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solady/tokens/WETH.sol";

import "./ToastNFT.sol";
import "src/Exchange.sol";

contract Setup {
    ToastNFT public toastNFT;
    Exchange public exchange;
    WETH public weth;
    Toast public toast;
    address public owner;
    bytes public sellSig;
    bool public isSolved;

    constructor() payable {
        owner = msg.sender;
        
        weth = new WETH();
        weth.deposit{value: 400 ether}();

        require(address(0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199).balance == 0);
        weth.transfer(0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199, weth.balanceOf(address(this)));
    
        exchange = new Exchange();
        toastNFT = new ToastNFT();
        toast = new Toast(weth, toastNFT, exchange);

        toastNFT.mint(msg.sender, 1337, 1337);
    }

    function setSig(bytes memory sig) external {
        sellSig = sig;
    }

    function solve() external {
        if(toastNFT.balanceOf(msg.sender, 1337) > 10)
            isSolved = true;
    }
}

contract Toast {
    WETH weth;
    ToastNFT toastNFT;
    Exchange exchange;

    modifier onlyExchange() {
        require(
            msg.sender == address(exchange),
            "sender not exchange"
        );
        _;
    }

    constructor(WETH _weth, ToastNFT _toastNFT, Exchange _exchange) {
        weth = _weth;
        toastNFT = _toastNFT;
        exchange = _exchange;
    }

    function pwn(address[] calldata recipients, address buyer, address seller, uint256 value) external onlyExchange {
        require(value >= 400e18);

        weth.transferFrom(buyer, seller, value);

        for(uint256 i = 0; i < recipients.length; i++) {
            try toastNFT.safeTransferFrom(seller, recipients[i], 1337, 1, '') {} catch {}
        }
    }
}