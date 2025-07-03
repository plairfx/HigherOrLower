// SPDX-License-Identifier: MIT

import {Test, console} from "forge-std/Test.sol";
import {HigherOrLower} from "../src/HigherOrLower.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

pragma solidity ^0.8.20;

contract HigherOrLowerTest is Test {
    HigherOrLower public HOL;
    VRFCoordinatorV2_5Mock public VRF;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() external {
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);

        // vrf shit..
        VRF = new VRFCoordinatorV2_5Mock(0.001 ether, 0.00001 ether, 0.0001 ether);
        uint256 subid = VRF.createSubscription();
        HOL = new HigherOrLower(address(VRF), subid);

        VRF.addConsumer(subid, address(HOL));
        VRF.fundSubscription(subid, 10000000 ether);

        vm.deal(address(HOL), 10 ether);
    }

    function test_BettingWorks() public {
        uint256 balanceBefore = address(HOL).balance;
        uint256 aliceBalanceBefore = alice.balance;
        console.log(address(HOL));
        vm.startPrank(alice);

        assertEq(1, HOL.getCurrentRound());

        HOL.bet{value: 0.01 ether}(0);

        assertEq(balanceBefore + 0.01 ether, address(HOL).balance);
        assertEq(aliceBalanceBefore - 0.01 ether, alice.balance);

        vm.startPrank(address(VRF));
        VRF.fulfillRandomWords(1, address(HOL));
        assertEq(address(alice), HOL.getPlayer());
        assertEq(2, HOL.getCurrentRound());
        assertEq(aliceBalanceBefore + 0.01 ether, alice.balance);
    }

    function test_BetErrorsWorkCorrectly() public {
        console.log(address(HOL));
        vm.startPrank(alice);
        vm.expectRevert();
        HOL.bet{value: 0.1 ether}(0);

        vm.expectRevert();
        HOL.bet{value: 0.01 ether}(2);
        vm.stopPrank();

        vm.startPrank(address(HOL));
        (bool success,) = alice.call{value: address(HOL).balance}("");
        assertEq(address(HOL).balance, 0 ether);

        vm.startPrank(alice);
        vm.expectRevert();
        HOL.bet{value: 0.01 ether}(1);

        vm.deal(address(HOL), 1 ether);
        HOL.bet{value: 0.01 ether}(1);

        vm.startPrank(bob);
        vm.expectRevert("Caller is not equal to Player");

        HOL.bet{value: 0.01 ether}(1);
        assertNotEq(HOL.getPlayer(), address(bob));
    }

    function test_PlayerLosesBet() public {
        uint256 balanceBefore = address(HOL).balance;
        uint256 aliceBalanceBefore = alice.balance;
        console.log(address(HOL));
        vm.startPrank(alice);

        HOL.bet{value: 0.01 ether}(0);
        assertEq(balanceBefore + 0.01 ether, address(HOL).balance);
        assertEq(aliceBalanceBefore - 0.01 ether, alice.balance);

        vm.startPrank(address(VRF));
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 0;
        VRF.fulfillRandomWordsWithOverride(1, address(HOL), randomWords);
    }
}
