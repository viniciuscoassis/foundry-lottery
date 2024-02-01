// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    /**
     * Events
     */
    event EnteredRaffle(address indexed player);

    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();
        (entranceFee, interval, vrfCoordinator, gasLane, subscriptionId, callbackGasLimit, link) =
            helperConfig.activeNetworkConfig();
        console.log("Raffle address: %s", address(raffle));
        vm.deal(PLAYER, STARTING_BALANCE);
    }

    function testRaffleInitializeInOpenState() external view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleInitializeWithCorrectEntranceFee() external view {
        assert(raffle.getEntranceFee() == entranceFee);
    }
    /**
     * Enter Raffle
     */

    function testRaffleRecordsWhenTheyEnter() public {
        // Arrange
        vm.prank(PLAYER);

        // Act
        raffle.enterRaffle{value: entranceFee}();

        // Assert
        assert(raffle.getPlayers().length == 1);
        assert(raffle.getPlayers()[0] == PLAYER);
    }

    function testEnterRaffleRevertWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);

        // Act / Assert
        vm.expectRevert(Raffle.Raffle__notEnoughEthSent.selector);
        raffle.enterRaffle();
    }

    function testeEmitsEventOnEntrance() public {
        // Arrange
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCantEnterWhileRaffleIsCalculating() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        // Act / Assert

        vm.expectRevert(Raffle.Raffle__raffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }
}
