// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "src/Setup.sol";

contract SetupScript is Script {
    Setup setup;
    uint256 ownerPK;

    event log_named_address(string memo, address);

    function setUp() external {
        ownerPK = vm.envUint("owner_private_key");
    }

    function hashOrder(Order memory order) internal pure returns (bytes32 hash) {
        bytes32 ORDER_TYPEHASH = 0xca2b31eece9789f8640037795ba5e3065ba8d82ef095c0f8c0f4310a0d1f96ea;
        bytes memory part1;
        bytes memory part2;
        {
            part1 = abi.encode(
                ORDER_TYPEHASH,
                order.exchange,
                order.maker,
                order.salt,
                order.taker,
                order.side,
                order.saleKind
            );
        }
        {
            part2 = abi.encode(
                order.target,
                order.howToCall,
                keccak256(order.calldata_),
                order.staticTarget,
                order.paymentToken,
                order.basePrice,
                order.expirationTime,
                order.feeMethod
            );
        }
        return keccak256(abi.encodePacked(part1, part2));
    }

    function run() external {
        vm.startBroadcast(ownerPK);
        {
            uint64 nonce = vm.getNonce(vm.addr(ownerPK));

            setup = new Setup{value: 400 ether}();

            WETH weth = setup.weth();
            Exchange exchange = setup.exchange();
            ToastNFT toastNFT = setup.toastNFT();
            Toast toast = setup.toast();

            toastNFT.setApprovalForAll(address(toast), true);

            emit log_named_address("Deployed to", address(setup));

            Order memory sell = Order({
                exchange: address(exchange),
                maker: vm.addr(ownerPK),
                salt: nonce,
                taker: address(0),
                side: SaleKindInterface.Side.Sell,
                saleKind: SaleKindInterface.SaleKind.FixedPrice,
                target: address(toast),
                howToCall: AuthenticatedProxy.HowToCall(0),
                calldata_: '',
                staticTarget: address(0),
                paymentToken: address(weth),
                basePrice: 400e18,
                expirationTime: 0,
                feeMethod: FeeMethod(0),
                sig: ''
            });

            bytes32 hash = hashOrder(sell);
            
            bytes32 DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
            bytes32 domainHash = keccak256(abi.encode(
                DOMAIN_TYPEHASH,
                keccak256("Toast"),
                keccak256("0"),
                block.chainid,
                address(exchange)
            ));

            bytes32 digest = keccak256(
                abi.encodePacked(
                    hex'1901',
                    domainHash,
                    hash
                )
            );

            (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPK, digest);
            sell.sig = abi.encodePacked(r, s, v);

            setup.setSig(sell.sig);
        }
        vm.stopBroadcast();
    }
}