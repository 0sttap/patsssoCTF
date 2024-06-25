// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";

import {CheaperWETH} from "src/ctf-2/CheaperWETH.sol";

// forge test --mc GifterTest -vvv
contract CheaperWETHTest is Test {
    CheaperWETH internal _cheaperWETH;

    address internal _user;
    uint256 internal _privateKey;

    function setUp() public {
        (_user, _privateKey) = makeAddrAndKey("user");

        _cheaperWETH = new CheaperWETH();

        vm.deal(address(this), 100 ether);
        _cheaperWETH.deposit{value: 100 ether}();
    }

    function testCheaperWETH() public {
        assertEq(_cheaperWETH.balanceOf(_user), 0);

        uint256 contractBalance = address(_cheaperWETH).balance;
        uint256 userDeposit = 15 ether;

        vm.deal(_user, userDeposit);

        vm.prank(_user);
        _cheaperWETH.deposit{value: userDeposit}();

        assertEq(_cheaperWETH.balanceOf(_user), userDeposit);

        /**
            Write a solution to the challenge that will allow you to steal the CheaperWETH's funds.
        */

        assertEq(address(_user).balance, contractBalance + userDeposit);
        assertEq(address(_cheaperWETH).balance, 0);
    }

    function testApproveCheaperWETH() public {
        address marketplace = makeAddr("marketplace");

        assertEq(_cheaperWETH.allowance(_user, marketplace), 0);

        vm.prank(_user);
        _cheaperWETH.approve(marketplace, 100 ether);

        assertEq(_cheaperWETH.allowance(_user, marketplace), 100 ether);
    }

    function testTransferCheaperWeth() public {
        vm.deal(_user, 10 ether);

        address receiver = makeAddr("receiver");

        vm.startPrank(_user);
        _cheaperWETH.deposit{value: 10 ether}();
        _cheaperWETH.transfer(receiver, 3 ether);
        vm.stopPrank();

        assertEq(_cheaperWETH.balanceOf(receiver), 3 ether);
        assertEq(_cheaperWETH.balanceOf(_user), 7 ether);
    }

    function testTransferFromCheaperWETH() public {
        address spender = makeAddr("spender");
        address receiver = makeAddr("receiver");

        vm.deal(spender, 10 ether);

        vm.startPrank(spender);
        _cheaperWETH.deposit{value: 10 ether}();
        _cheaperWETH.approve(receiver, 5 ether);
        vm.stopPrank();

        vm.prank(receiver);
        _cheaperWETH.transferFrom(spender, receiver, 3 ether);

        assertEq(_cheaperWETH.balanceOf(receiver), 3 ether);
        assertEq(_cheaperWETH.balanceOf(spender), 7 ether);

        assertEq(_cheaperWETH.allowance(spender, receiver), 2 ether);
    }
}
