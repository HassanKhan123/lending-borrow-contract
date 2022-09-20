pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Lending {
    using Address for address;

    enum requestStatus {
        PENDING,
        ONGOING,
        COMPLETED
    }

    IERC20 public tokenAddress;
    uint256 public borrowingIntrest;
    uint256 public registrationCollateral;

    struct BorrowerRequest {
        address borrower;
        address lender;
        uint256 amount;
        uint256 initiationTime;
        uint256 duration;
        requestStatus status;
    }

    mapping(address => bool) public borrower;
    mapping(address => bytes32[]) public borrowRequestId;
    mapping(bytes32 => BorrowerRequest) public borrowRequest;

    event BorrowerRegistered(address addedBorrower);
    event BorrowerRequestAdded(
        bytes32 id,
        address borrower,
        uint256 amount,
        uint256 timeStampDuration
    );
    event BorrowerRequestAccepted(
        bytes32 id,
        address lender,
        uint256 startingTimeStamp
    );
    event BorrowerRequestCompleted(bytes32 id, uint256 completionTime);

    constructor(IERC20 _token) {
        tokenAddress = _token;
        borrowingIntrest = 100000000000000000;
        registrationCollateral = 100000000000000000;
    }

    function registerAsBorrower() public payable {
        address sender = msg.sender;
        require(!sender.isContract(), "Sender Cannot be Contract");
        require(!borrower[sender], "Sender should not already be a borrower");
        borrower[sender] = true;
        address(this).call{value: registrationCollateral}("");
        emit BorrowerRegistered(sender);
    }

    function requestFundsToBorrow(uint256 _amount, uint256 _duration) public {
        address sender = msg.sender;
        require(!sender.isContract(), "sender Cannot be Contract");
        require(borrower[sender], "Sender should be a borrower");
        require(_duration >= 60, "Duration should be greater than 1 minute");
        require(borrower[sender], "Borrower should be Registered");
        require(
            _amount > 0 && _duration > 0,
            "Amount and duration should not be zero"
        );
        BorrowerRequest memory br = BorrowerRequest(
            sender,
            address(0),
            _amount,
            0,
            _duration,
            requestStatus.PENDING
        );
        bytes32 requestId = keccak256(abi.encode(block.timestamp, sender));
        borrowRequest[requestId] = br;
        borrowRequestId[sender].push(requestId);

        emit BorrowerRequestAdded(requestId, sender, _amount, _duration);
    }

    function AcceptRequest(bytes32 requestId) public {
        address sender = msg.sender;
        uint256 timestamp = block.timestamp;
        require(!sender.isContract(), "Sender Cannot be Contract");

        require(
            tokenAddress.balanceOf(sender) >= borrowRequest[requestId].amount,
            "Lender does have the required funds to lend"
        );
        tokenAddress.transferFrom(
            sender,
            borrowRequest[requestId].borrower,
            borrowRequest[requestId].amount
        );
        borrowRequest[requestId].lender = sender;
        borrowRequest[requestId].initiationTime = timestamp;
        borrowRequest[requestId].status = requestStatus.ONGOING;

        emit BorrowerRequestAccepted(requestId, sender, timestamp);
    }

    function payBackLender(bytes32 requestId) public {
        address sender = msg.sender;
        uint256 timestamp = block.timestamp;
        require(
            borrowRequest[requestId].borrower == sender,
            "Only Borrower Can Return Funds"
        );
        uint256 borrowDuration = borrowRequest[requestId].initiationTime +
            borrowRequest[requestId].duration;
        require(
            timestamp >= borrowDuration,
            "You still have time until you can return funds"
        );
        uint256 durationInMinutes = borrowRequest[requestId].duration / 60;
        uint256 returnAmount = borrowRequest[requestId].amount +
            (borrowRequest[requestId].amount *
                borrowingIntrest *
                durationInMinutes) /
            10000;
        tokenAddress.transferFrom(
            sender,
            borrowRequest[requestId].lender,
            returnAmount
        );
        borrowRequest[requestId].status = requestStatus.COMPLETED;
        emit BorrowerRequestCompleted(requestId, timestamp);
    }
}
