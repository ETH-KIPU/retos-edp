// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ScrollSepoliaAuction {
    address public owner;
    address public seller;
    address public highestBidder;
    uint256 public highestBid;
    uint256 public auctionEndTime;
    //uint256 public minimumIncrease;
    uint256 public constant MINIMUM_INCREASE = 105; // It's 5%, so it shouldn't be in the constructor where 5 is unclear.
    //uint256 public commissionRate;
    uint256 public constant COMISSION_RATE = 2; // It's 2%, no change
    bool public ended;

    struct Bidder {
        address bidder;
        uint256 amount;
    }

    Bidder[] public bids;
    mapping(address => uint256) public deposits;

    event NewBid(address indexed bidder, uint256 amount); // english is better
    event AuctionEnded(address indexed winner, uint256 amount); // english is better

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the auction owner"); // use short strings and in english
        _;
    }

    modifier beforeEnd() { // I would use isFinished and isNotFinished instead of before and after. I think it is more clear but ok.
        require(block.timestamp < auctionEndTime, "Auction has ended"); // english
        _;
    }

    modifier afterEnd() {
        require(block.timestamp >= auctionEndTime, "Auction has not ended");
        _;
    }

    constructor(address _seller, uint256 _biddingTime/*, uint256 _minimumIncrease*/) {
        owner = msg.sender;
        seller = _seller;
        auctionEndTime = block.timestamp + _biddingTime;
        /*minimumIncrease = _minimumIncrease;*/ // not using it as a constant is better
        //commissionRate = 2; // constant, no change
    }

    function finishTime() external {
        auctionEndTime = block.timestamp - 1;
    }

    function bid() external payable beforeEnd {
        uint256 _highestBid = highestBid; // added for gas optimiazation (just one read into the storage). and changed where it is used
        // math changed: _highestBid * 105 /100 (It is more accurate than _highestBid * 5 / 100 )
        require(msg.value > _highestBid * MINIMUM_INCREASE / 100, "Offer must exceed min. %"); // short string + english

        highestBidder = msg.sender; // logic change because it was wrong
        highestBid = msg.value;

        deposits[msg.sender] += msg.value;// change for gas optimization

        bids.push(Bidder({bidder: msg.sender, amount: msg.value}));
        // Extender la subasta si es necesario
        uint256 _auctionEndTime = auctionEndTime;
        if (block.timestamp >= _auctionEndTime - 10 minutes) {
            auctionEndTime = _auctionEndTime + 10 minutes;
        }
        emit NewBid(msg.sender, msg.value);
    }

    function returnDeposits() external onlyOwner afterEnd {
        require(!ended, "Deposits have been refunded"); // short string and english
        ended = true;

        uint256 len = bids.length; // added for gas optimization inside the loop
        address _highestBidder = highestBidder; // added for gas optimization inside the loop
        bool success; // optimize gas and don't shadow declaration
        for (uint i = 0; i < len; i++) {
            address _bidder = bids[i].bidder; // added for gas optimization inside the loop
            if (_bidder != _highestBidder) { // changedlogicbecause it was wrong
                uint256 amount = deposits[_bidder]; // + bids[i].amount; This part shouldnt be here
                uint256 fee = (amount * COMISSION_RATE) / 100; // change for the constant
                uint256 refund = amount - fee;
                deposits[_bidder] = 0;
                (success, ) = _bidder.call{value: refund}(""); // declaring outside to avoid warning and optimizing gas
                require(success, "Failure to send refund"); // english
            }
        }
        uint256 _highestBid = highestBid;
        emit AuctionEnded(_highestBidder, _highestBid);

        // Transferir los fondos al vendedor
        (success, ) = seller.call{value: _highestBid}("");

        require(success, "Failure to send seller"); // english
    }

    // we said not to pay for gas fee when doing the partial withdra but it is working
    function withdrawPartial() external beforeEnd {
        uint256 totalDeposit = deposits[msg.sender];
        uint256 lastBidAmount = 0;

        // Encontrar la ultima oferta del ofertante
        for (uint i = 0; i < bids.length; i++) {
            if (bids[i].bidder == msg.sender) {
                lastBidAmount = bids[i].amount;
            }
        }

        require(totalDeposit > lastBidAmount, "No excess funds to withdraw"); // short string + english + no need in solc > 0.8.0
        uint256 excessAmount = totalDeposit - lastBidAmount;
        deposits[msg.sender] = lastBidAmount;

        uint256 fee = (excessAmount * COMISSION_RATE) / 100; // changed for the constant
        uint256 refund = excessAmount - fee;
        
        (bool success, ) = msg.sender.call{value: refund}("");
        require(success, "fail to send partial refund"); // short string + english
    }


    // This function is to take out the ethers that are left. We don't write it in the same ending function
    // because if for some reason it breaks the previous one (an array to long) we can mannage to get the
    //funds and solve the problem. To make it more descentralized we could make that in case it breaks each
    // person could get their funds, and the owner its own.
    function withdrawAll() external afterEnd onlyOwner {
        // Transferir los fondos al owner para que no quede trabado en el contrato
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "fail to send funds to owner"); // short string + english
    }



    function mostrarGanador() external view returns (address, uint256) {
        require(ended, "Auction has not ended"); // english
        return (highestBidder, highestBid);
    }

    function mostrarOfertas() external view returns (Bidder[] memory) {
        return bids;
    }
}
