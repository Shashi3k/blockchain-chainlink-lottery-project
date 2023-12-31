// SPDX-License-identifier: MIT


pragma solidity 0.8.19;

import "../node_modules/@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";

contract CoinFlip is VRFV2WrapperConsumerBase{

    constructor() payable VRFV2WrapperConsumerBase(linkAddress, vefWrapperAddress){}  
    event CoinFlipRequest(uint256 requestId);
    event CoinFlipResult(uint256 requestId, bool didWin);

    struct CoinFlipStatus{
        uint256 fees;
        uint256 randomWord;
        address player;
        bool didWin;
        bool fulfilled;
        CoinFlipSelection choice;
    }

    address constant linkAddress=0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address constant vefWrapperAddress=0x708701a1DfF4f478de54383E49a627eD4852C816;

    enum CoinFlipSelection{
        HEADS,
        TAIL
    }

    mapping (uint256 => CoinFlipStatus) public statuses;

    uint128 constant entryFees = 0.001 ether;
    uint32 constant callBackGasLimit = 1_000_000;
    uint32 constant numWords = 1;
    uint16 constant requestConfirmations = 3;

    function flip(CoinFlipSelection choice) external payable returns (uint256){
        require(msg.value==entryFees, "Entry fees not sent");

        uint requestId = requestRandomness(callBackGasLimit, requestConfirmations, numWords);

        statuses[requestId] = CoinFlipStatus({
            fees: VRF_V2_WRAPPER.calculateRequestPrice(callBackGasLimit),
            randomWord: 0,
            player: msg.sender,
            didWin: false,
            fulfilled: false,
            choice: choice
        });

        emit CoinFlipRequest(requestId);
        return requestId;

        
    }
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override{
        require(statuses[requestId].fees>0,"Request not found");
        statuses[requestId].randomWord = randomWords[0];

        CoinFlipSelection result = CoinFlipSelection.HEADS;
        if(randomWords[0]%2==0){
            result = CoinFlipSelection.TAIL;
        }

        if (statuses[requestId].choice == result){
            statuses[requestId].didWin = true;
            payable(statuses[requestId].player).transfer(entryFees*2);
        }

        emit CoinFlipResult(requestId, statuses[requestId].didWin);
    }

    function getStatus(uint256 requestId) public view returns(CoinFlipStatus memory){
        return statuses[requestId];
    }
}