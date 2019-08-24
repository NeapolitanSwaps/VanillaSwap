pragma solidity ^0.4.24;

import "./interface/ICERC20.sol";

contract Cherryswap {

  /******************
  INTERNAL ACCOUNTING
  ******************/
  uint256 public swapsCounter;

  ICERC20 public cherryToken; // = DAI

  enum Status {
    Open,
    Running,
    Closed
  }

  enum Bet {
    Long,
    Short
  }

  struct Swap {
    uint256 swapId;
    uint256 openingTime;
    uint256 startingTime;
    uint256 endingTime;
    uint256 startingRate;
    uint256 endingRate;
    Status status;
  }

  struct SwapInfo {
    address[] participants;
    uint256[] depositedValues;
    uint256 participantsCounter;
    Bet[] bets;
  }

  Swap[] public swaps;
  mapping (uint256 => SwapInfo) public swapById;

  constructor(
    address _cherryToken
  ) public {
    require(_cherryToken != address(0), "Cherryswap::constructor - _cherryToken cannot be 0");
            
    cherryToken = ICERC20(_cherryToken);
    swapsCounter = 0;
  }

  modifier hasEnded(uint256 swapId) {
    if(swapId > 0) {
      Swap memory swap = swaps[swapId];
      require(now >= swap.endingTime, "Cherryswap::hasEnded - swap not ended yet");
    }
    _;
  }

  modifier isOpen(uint256 swapId) {
    Swap memory swap = swaps[swapId];
    require(now < swap.startingTime, "Cherryswap::isOpen - swap is running or closed");
    _;
  }

  modifier isRunning(uint256 swapId) {
    Swap memory swap = swaps[swapId];
    require((now > swap.startingTime) && (now < swap.endingTime), "Cherryswap::isOpen - swap is open or closed");
    _;
  }

  function createSwap(
    address _participant,
    uint256 _startingTime,
    uint256 _endingTime
  ) public hasEnded(swapsCounter) {
    // increment swaps counter
    swapsCounter++;

    // create new swap
    Swap memory swap = Swap({
      swapId: swapsCounter,
      openingTime: now,
      startingTime: _startingTime,
      endingTime: _endingTime,
      startingRate: 0,
      endingRate: 0,
      status: Status.Open
    });
    swaps.push(swap);
  }

  function startSwap() public isOpen(swapsCounter) {
    require(now == swaps[swapsCounter].startingTime, "Cherryswap::startSwap - mmmmmm it is not starting time yet!");
    
    swaps[swapsCounter].status = Status.Running;
    //todo: need to talk with compound about some business
    //get starting rate
  }

  function closeSwap() public hasEnded(swapsCounter) {
    swaps[swapsCounter].status = Status.Closed;

    //todo: talk with compound about some business
    //get contract DAI supply & convergent rate
    
    
    //check if long or short won and send token 
  }

  function deposit(
    address _participant,
    uint256 _depositedValue,
    uint8 _uintBet
  ) public isOpen(swapsCounter) {
    require(_participant != address(0), "Invalid participant address");

    // collect proposal deposit from proposer and store it in the Moloch until the proposal is processed
    require(cherryToken.transferFrom(_participant, address(this), _depositedValue), "Cherryswap::deposit - deposit token transfer failed");

    SwapInfo memory swapInfo;
    swapInfo.participants[swapsCounter] = _participant;
    swapInfo.depositedValues[swapsCounter] = _depositedValue;
    swapInfo.bets[swapsCounter] = Bet(_uintBet);

    swapById[swapsCounter] = swapInfo;

    //todo: talk with compound about some business
    //borrow or mint or whatever
  }

}


