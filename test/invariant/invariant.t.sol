// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {HigherOrLower} from "../../src/HigherOrLower.sol";
import {Test, console2, console, StdInvariant, Test} from "forge-std/Test.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract invariant is StdInvariant, Test {
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
        vm.startPrank(alice);
        HOL.bet{value: 0.01 ether}(1);
    }

    function invariant_PlayerWillAlwaysRemainTheSame() public {
        assertEq(HOL.getPlayer(), address(alice));
    }

    function invariant_currentNumberAndRoundStayTHeSame() public {
        assertEq(HOL.getCurrentRound(), 1);
    }
}
