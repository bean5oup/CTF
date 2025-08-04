// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

contract ToastScript is Script {
    uint256 scamPK;

    event log_named_address(string memo, address);

    function setUp() external {
        scamPK = 0xdf57089febbacf7ba0bc227dafbffa9fc08a93fdc68e1e42411a14efcf23656e;
    }

    function run() external {
        vm.startBroadcast(vm.envUint("user_private_key"));
        // address owner = vm.addr(vm.envUint("owner_private_key"));
        // uint64 nonce = vm.getNonce(owner);

        Kernel kernel = new Kernel();
        vm.stopBroadcast();

        bytes memory result;
        {
            string[] memory inputs = new string[](8);
            inputs[0] = "cast";
            inputs[1] = "wallet";
            inputs[2] = "sign-auth";
            inputs[3] = vm.toString(address(kernel));
            inputs[4] = "--private-key";
            inputs[5] = vm.toString(bytes32(scamPK));
            inputs[6] = "--rpc-url";
            inputs[7] = vm.envString("RPC_URL");
            result = vm.ffi(inputs);
        }

        {
            string[] memory inputs = new string[](9);
            inputs[0] = "cast";
            inputs[1] = "send";
            inputs[2] = "0x0000000000000000000000000000000000000000";
            inputs[3] = "--private-key";
            inputs[4] = vm.envString("owner_private_key");
            inputs[5] = "--auth";
            inputs[6] = vm.toString(result);
            inputs[7] = "--rpc-url";
            inputs[8] = vm.envString("RPC_URL");
            result = vm.ffi(inputs);
        }

        emit log_named_address("Deployed to", address(0));
    }
}

contract Kernel {
    receive() external payable {
        payable(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266).transfer(msg.value);
    }
}