// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import Klaytn's KIP7 interface for ERC-20 token
import "@klaytn/contracts/token/ERC20/ERC20.sol";
import "@klaytn/contracts/KIP/token/KIP17/extensions/IKIP17Enumerable.sol";
import "@klaytn/contracts/KIP/token/KIP17/extensions/IKIP17Metadata.sol";
import "./LIX.sol" ;


contract LendingProtocol {
    // State variables
    address public owner;
    LIXToken public interestToken;
    uint256 public LOCK_DURATION;
    uint256 public constant LOCK_DURATION_1 = 180 days;
    uint256 public constant LOCK_DURATION_2 = 360 days;
    uint256 public constant LOCK_DURATION_3 = 540 days;
    uint256 public interestRate = 10; // Interest rate in percentage

    struct Deposit {
        uint256 amount; // Amount of KLAY deposited
        uint256 start;
        uint256 lockTime;
        uint256 _type;
        uint256 count;
        bool launchpad;
        address[] portfolio; // 상품 1
    }

    mapping(address => Deposit) public deposits;
    mapping(address => mapping(address=>uint256)) public fundedamount;
    address[][] public portfolios; //  상품1 상품 2 상품 3  ... 4 5 -> 상품마다 ICO 컨트랙트의 주소


    // Events
    event Deposited(address indexed user, uint256 amount, uint256 _type);
    event InterestPaid(address indexed user, uint256 interest);
    event LaunchPaid(address indexed user, address indexed _to, uint256 interest);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor(uint256 initialSupply ) {
        owner = msg.sender;
        interestToken = new LIXToken(initialSupply);
    }

    function supplymint(uint256 _amount) internal {
        interestToken.mint(address(this), _amount);
    }


    function ownermint(uint256 _amount) public onlyOwner {
        interestToken.mint(address(this), _amount);
    }

    function acceptporfolios(uint256 _index, address _address) public onlyOwner {
        if (portfolios.length <= _index) {
            portfolios.push();
        }
        portfolios[_index].push(_address);
    }

    function deleteporfolios(uint256 _index, address _address) public onlyOwner {
        for(uint256 i = 0; i< portfolios[_index].length; i++){
            if(portfolios[_index][i] == _address){
                delete portfolios[_index][i];
            }
        } // 사기치려고 하면 안되니까
    }

    function getfundedamount(address _from, address _to) public view returns (uint256) {
        return fundedamount[_from][_to];
    }

    function modifyfundedamount(address _project, address _user, uint256 _amount) public onlyOwner {
        fundedamount[_project][_user] = _amount;
    }

    function getportfolio(address _address) public view returns (address[] memory) {
        return deposits[_address].portfolio;
    }

    





    // Deposit function to accept KLAY and lock it
    function deposit(uint256 _type) external payable {
        require(msg.value > 0, "Deposit value must be greater than 0");
        if(_type == 1){
            LOCK_DURATION = LOCK_DURATION_1;
            deposits[msg.sender] = Deposit({
            amount: msg.value/1e18,
            start: block.timestamp,
            lockTime: block.timestamp + LOCK_DURATION,
            _type: _type,
            count: 0,
            launchpad: false,
            portfolio: new address[](0)
        });
        }
        else if(_type == 2){
            LOCK_DURATION = LOCK_DURATION_2;
            deposits[msg.sender] = Deposit({
            amount: msg.value/1e18,
            start: block.timestamp,
            lockTime: block.timestamp + LOCK_DURATION,
            _type: _type,
            count: 0,
            launchpad: false,
            portfolio: new address[](0)
        });
        }
        else if(_type == 3){
            LOCK_DURATION = LOCK_DURATION_3;
            deposits[msg.sender] = Deposit({
            amount: msg.value/1e18,
            start: block.timestamp,
            lockTime: block.timestamp + LOCK_DURATION,
            _type: _type,
            count: 0,
            launchpad: false,
            portfolio: new address[](0)
        });
        }
        else{
            revert("Invalid type");
        }
        emit Deposited(msg.sender, msg.value, _type);
    }

    function setLaunch() public {
        Deposit storage userDeposit = deposits[msg.sender];
        require(userDeposit.amount > 0, "No deposit to pay interest on");
        userDeposit.launchpad = true;
    }

    function setPortfolio(uint256 portfolios_index) public {
        Deposit memory userDeposit = deposits[msg.sender];
        require(userDeposit.amount > 0, "No deposit to pay interest on");
        require(userDeposit.launchpad == true, "Not launchpad user");
        userDeposit.portfolio = portfolios[portfolios_index]; 
        for(uint256 i = 0; i<portfolios[portfolios_index].length; i++){
            fundedamount[portfolios[portfolios_index][i]][msg.sender] = 0;
        }
    }

    // Function to pay out interest in ERC-20 tokens
    function payInterest(address beneficiary) public {
        require(msg.sender == beneficiary, "Self-get interest.");
        Deposit storage userDeposit = deposits[beneficiary];
        require( block.timestamp - userDeposit.start  >= userDeposit._type * (90 days) , "Deposit is still locked");
        require(userDeposit.amount > 0, "No deposit to pay interest on");
        uint256 unit = 30 days; 
        uint256 q;
        if( userDeposit.lockTime > block.timestamp)
        {
            q = 6*userDeposit._type;
        }
        else{
            q = (block.timestamp - userDeposit.start) / unit ;
        }
        
        uint256 can_receive = (q - userDeposit.count) * calculateInterest(userDeposit.amount);
        userDeposit.count = q; 

        if( can_receive > interestToken.balanceOf(address(this)))
        {
            supplymint(can_receive - interestToken.balanceOf(address(this)));
        }
        
        if(userDeposit.launchpad == true){
            for(uint256 i = 0; i<userDeposit.portfolio.length; i++){
                require(userDeposit.portfolio[i] != address(0), "Invalid address");
                require(userDeposit.portfolio[i] != msg.sender, "Self-get interest.");
                interestToken.transfer(userDeposit.portfolio[i], can_receive/userDeposit.portfolio.length);
                fundedamount[userDeposit.portfolio[i]][msg.sender] += can_receive/userDeposit.portfolio.length;
                //락
                emit LaunchPaid(beneficiary, userDeposit.portfolio[i], can_receive/userDeposit.portfolio.length);
            }
        }  
        else
        {
            require(interestToken.transfer(beneficiary, can_receive), "Interest payment failed");
            emit InterestPaid(beneficiary, can_receive);
        }        

        
    }


    // Calculate interest based on the deposit amount
    function calculateInterest(uint256 _amount) public view returns (uint256) {
        return (_amount * interestRate) / 100;
    }

    // Withdraw function for users to withdraw their KLAY after lock period
  
    function withdraw() external {
        Deposit storage userDeposit = deposits[msg.sender];
        require(block.timestamp >= userDeposit.lockTime, "Deposit is still locked");
        require(userDeposit.amount > 0, "No funds to withdraw");

        uint256 amountToWithdraw = userDeposit.amount;
        bool success = payable(msg.sender).send(amountToWithdraw * 1e18); // Transfer KLAY to msg.sender
        require(success, "Failed to send KLAY");

        userDeposit.amount = 0;
        emit Deposited(msg.sender, amountToWithdraw, userDeposit._type);
    }



    // Function to allow owner to change interest rate
    function setInterestRate(uint256 _newRate) external onlyOwner {
        interestRate = _newRate;
    }

    // Function to retrieve contract's KLAY balance
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Function to retrieve contract's ERC-20 token balance
    function getTokenBalance() external view returns (uint256) {
        return interestToken.balanceOf(address(this));
    }
}

