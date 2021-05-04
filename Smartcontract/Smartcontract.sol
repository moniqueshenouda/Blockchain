pragma solidity >0.4.23 <0.6.0;

contract Auction {
   
    mapping(bytes32 =>uint) blindBid;
    mapping(address =>bool) bidders;
    mapping(address => bytes32) public bids;
    mapping(address => uint) pendingReturns;
    mapping(address=>uint) honestbidders;
    uint mindep= 1;
    uint cheatersdeposit=0; 
    uint public biddingEnd;
    uint public revealEnd;
    address[] honest;
    address[] allbids;
    address payable public auctionmanager;
    bool public ended;
    address public highestBidder;
    uint public highestBid;

    

    event AuctionEnded(address winner, uint highestBid);

    constructor(
        uint _biddingTime,
        uint _revealTime
    ) public {
        auctionmanager=msg.sender;
        biddingEnd = now + _biddingTime;
        revealEnd = biddingEnd + _revealTime;
    }

    function hash(address bidder, uint value, bytes32 nonce) public view  returns(bytes32){
        bytes32 check= keccak256(abi.encodePacked(msg.sender,value,nonce));
        return check;
        
    }

    function bid(bytes32 _blindedBid)public payable  {
        require(now < biddingEnd,"Bidding time ended.");
        require(msg.sender!=auctionmanager,"You are the auction manager. You can't bid.");
        require(!bidders[msg.sender],"You have already sent you bid");
        require(msg.value>mindep,"Message value is less than the minimum deposit!");
        
        blindBid[_blindedBid]=msg.value;
        bids[msg.sender]=_blindedBid;
        bidders[msg.sender]=true;
        allbids.push(msg.sender);
    }

    
   
    function reveal(uint value,bytes32 nonce) public payable {
       require(now > biddingEnd,"It is still bidding time.");
       require(now < revealEnd,"Revealing time ended.");
        
     
        bytes32 hashedBid = bids[msg.sender];
        bytes32 check= keccak256(abi.encodePacked(msg.sender,value,nonce));
           
        require(hashedBid == check,"NOT  EQUAL. Deposit won't be refunded");
      
        honest.push(msg.sender);
        honestbidders[msg.sender]=value;
        
     
    }
    
    function finalize()internal{
        uint length= honest.length;
        for(uint i=0;i<length;i++){
            checkBid(honest[i],honestbidders[honest[i]]);
        }
        for(uint i=0;i<length;i++){
            if(honest[i]!=highestBidder){
                 bytes32 hashedBid=bids[honest[i]];
                 uint deposit=blindBid[hashedBid];        
                 pendingReturns[honest[i]]=deposit;     
            }
            else if(honest[i]==highestBidder){
                bytes32 hashedBid=bids[honest[i]];
                 uint deposit=blindBid[hashedBid];
                 uint value=honestbidders[honest[i]];
                 if(deposit>value){
                     uint back=deposit-value;
                     pendingReturns[honest[i]]=back; 
                     
                 }
            }
            }
        uint length2=allbids.length;
        bool found;
        for(uint i =0;i<length2;i++){
            found=false;
            for(uint j=0;j<length;j++){
                if(allbids[i]==honest[j]){
                    found=true;
                }
           
            }   if(found==false){
                bytes32 hashedBid=bids[allbids[i]];
                 cheatersdeposit+=blindBid[hashedBid];  
            }
        }
        }
           
        

    function checkBid(address bidder, uint value) internal {
        if (value > highestBid) {
        
        highestBid = value;
        highestBidder = bidder;}
        
    }
    
    function withdraw() public {
        require(now > revealEnd,"Revealing time didn't end yet."); 
        require(ended,"Auction didn't end yet.");
        uint amount = pendingReturns[msg.sender];
       
           
            pendingReturns[msg.sender] = 0;

            msg.sender.transfer(amount);
        
    }
    
    function auctionEnd() public {
        require(now > revealEnd,"Revealing time didn't end yet.");
        require(!ended);
        finalize();
        emit AuctionEnded(highestBidder, highestBid);
        ended = true;
        auctionmanager.transfer(highestBid);
        auctionmanager.transfer(cheatersdeposit);
    }
    
}
