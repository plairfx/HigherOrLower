// SPDX-License-Identifier: MIT

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

pragma solidity ^0.8.20;

contract HigherOrLower is VRFConsumerBaseV2Plus {
    //Player Info
    address public player;
    uint8 playerChoice;

    //Game- Info
    uint16 currentNumber = 50;
    uint256 public currentRound = 1;
    mapping(uint256 => uint16) lastNumbers;
    uint256 subscriptionId;

    // Events
    event BetPlaced(uint256 amount, uint256 _currentRound, uint16 playersChoice);
    event BetWon(uint256 currentRounds, uint256 amount, uint16 upOrDown);
    event BetLost(uint256 currentRounds, uint256 amount, uint16 upOrDown);
    event RoundEnded(uint16 currentNumber, uint16 lastNumber);

    constructor(address vrfCoordinatior, uint256 subId) VRFConsumerBaseV2Plus(vrfCoordinatior) {
        subscriptionId = subId;
    }

    /**
     * this is the main function which allows you to bet in the HigherOrLower Game
     * @param higherorlower  choose 0 for HIGHER and 1 for DOWN.
     * @dev this will call VRF for 1 random word  get a new currentNumber from it _endRound.
     */
    function bet(uint8 higherorlower) public payable {
        if (player == address(0x0)) {
            player = msg.sender;
        } else {
            require(msg.sender == player, "Caller is not equal to Player");
        }

        require(
            address(this).balance >= 0.02 ether && msg.value == 0.01 ether,
            "Address has not enough balance or betting value needs to be 0.01 ether"
        );
        require(higherorlower == 0 || higherorlower == 1, "Choose 0 for Higher and 1 for Lower!");

        playerChoice = higherorlower;

        requestRandomWords();

        emit BetPlaced(msg.value, currentRound, higherorlower);
    }

    /**
     * This will end the round after fulfillRandomWords has been called by the VRF and decide if the player won or not.
     */
    function _endRound() internal {
        uint16 lastNumber = lastNumbers[currentRound];

        uint8 WinningAnswer = currentNumber > lastNumber ? 0 : 1;

        if (playerChoice != WinningAnswer) {
            emit BetLost(0.01 ether, currentRound, WinningAnswer);
        } else {
            (bool success,) = player.call{value: 0.02 ether}("");
            emit BetWon(0.01 ether, currentRound, WinningAnswer);
        }

        currentRound++;

        emit RoundEnded(currentNumber, lastNumber);
    }

    /**
     * @dev this will be called by vrf and set a new currentNumber.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        lastNumbers[currentRound] = currentNumber;
        currentNumber = uint16((randomWords[0] % 100) + 1);

        _endRound();
    }

    function requestRandomWords() internal returns (uint256 requestId) {
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subId: subscriptionId,
                requestConfirmations: 3,
                callbackGasLimit: 2_500_000,
                numWords: 1,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );
    }

    function getPlayer() public view returns (address) {
        return player;
    }

    function getCurrentRound() public view returns (uint256) {
        return currentRound;
    }

    receive() external payable {}
}
