pragma solidity ^0.5.12;

// Library & interfaces
import "./interface/ICERC20.sol";
import "./interface/ISwapMath.sol";
// Contracts
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "./Cherrypool.sol";
import "./CherryMath.sol";
import "interfaces/IERC20.sol";

/**
 * @title Cherryswap Contract
 * @dev This contract handle all swaping operations
 */
contract Cherryswap is Initializable, Cherrypool {
    enum Bet {Short, Long}

    uint256 oneMonthDuration = 60 * 60 * 24 * 30;
    uint256 maxInterestRatePaidPerBlock = (25 * 1e16) / (4 * 60 * 24 * 365);

    uint256 ALPHA = 150; //scaled by 100 so 150 = 1.5
    uint256 BETA = 0;

    struct Swap {
        address owner;
        uint256 swapId;
        uint256 openingTime;
        uint256 endingTime;
        uint256 fixedRateOffer;
        uint256 depositedValue;
        Bet bet;
    }

    Swap[] public swaps;

    CherryMath cherryMath;

    ERC20 token;
    IERC20 cToken;

    /**
     * @dev Initialize contract states
     */
    function initialize(address _token, address _cToken, address _cherryMath)
        public
        initializer
    {
        require(
            (_token != address(0)) && (_cToken != address(0)),
            "Cherryswap::invalid tokens addresses"
        );

        Cherrypool.initialize(_token, _cToken);
        cherryMath = CherryMath(_cherryMath);

        token = ERC20(_token);
        cToken = IERC20(_cToken);
    }

    /**
     * @dev function called by trader to enter into swap position.
     * @notice requires to check the current pool direction's utilization. 
     * If utilization is safe then position is entered.
     * trader enters position at the current rate offered by the pool.
     * @return 0 if successful otherwise an error code
     */
    function createPosition(uint256 _amount, uint8 _bet)
        public
        returns (uint256)
    {
        uint256 fixedRateOffer = 0;
        uint256 reserveAmount = futureValue.futureValue(
            _amount,
            maxInterestRatePaidPerBlock,
            0,
            oneMonthDuration
        ) -
            _amount;
        if (Bet(_bet) == Bet.Long) {
            require(
                CherryPool.canReserveLong(_amount),
                "Trying to reserve more than pool can take"
            );
            cherryPool._reserveLongPool(reserveAmount);
            fixedRateOffer =
                (cToken.supplyRatePerBlock() *
                    (1e18 - cherryPool.LongPoolUtilization() / ALPHA - BETA)) /
                1e18;
        }
        if (Bet(_bet) == Bet.Short) {
            require(
                CherryPool.canReserveShort(_amount),
                "Trying to reserve more than pool can take"
            );
            cherryPool._reserveShortPool(reserveAmount);
            fixedRateOffer =
                (cToken.supplyRatePerBlock() *
                    (1e18 + cherryPool.ShortPoolUtilization() / ALPHA + BETA)) /
                1e18;
        }
        swaps.push(
            Swap(
                msg.sender,
                numSwaps,
                now,
                oneMonthDuration,
                fixedRateOffer,
                _amount,
                _bet
            )
        );
    }

    /**
     * @dev traded withdraw from their position.
     * @notice if the time is after the end of the swap then they will receive the swap rate for
     * the duration of the swap and then the floating market rate between the end of the
     * swap and the current time.
     */
    function closePosition(uint256 _swapId) public returns (uint256) {
        return 0;
    }

    function reserveLongPool(uint256 _amount) internal isLongUtilized {
        _reserveLongPool(_amount);
    }

    function reserveShortPool(uint256 _amount) internal isShortUtilized {
        _reserveLongPool(_amount);
    }

    function numSwaps() public view returns (uint256) {
        return swaps.length();
    }
}
