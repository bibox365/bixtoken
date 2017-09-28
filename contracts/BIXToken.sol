pragma solidity ^0.4.11;


// This is just a contract of a BIX Token.
// It is a ERC20 token

import "zeppelin-solidity/contracts/token/StandardToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract BIXToken is StandardToken, Ownable{
    
    string public version = "1.0";
    string public name = "BIX Token";
    string public symbol = "BIX";
    uint8 public  decimals = 18;

    mapping(address=>uint256)  lockedBalance;
    mapping(address=>uint)     timeRelease; 
    
    uint256 internal constant INITIAL_SUPPLY = 500 * (10**6) * (10 **18);
    uint256 internal constant DEVELOPER_RESERVED = 175 * (10**6) * (10**18);

    //address public developer;
    //uint256 internal crowdsaleAvaible;


    event Burn(address indexed burner, uint256 value);
    event Lock(address indexed locker, uint256 value, uint releaseTime);
    event UnLock(address indexed unlocker, uint256 value);
    

    // constructor
    function BIXToken(address _developer) { 
        balances[_developer] = DEVELOPER_RESERVED;
        totalSupply = DEVELOPER_RESERVED;
    }

    //balance of locked
    function lockedOf(address _owner) public constant returns (uint256 balance) {
        return lockedBalance[_owner];
    }

    //release time of locked
    function unlockTimeOf(address _owner) public constant returns (uint timelimit) {
        return timeRelease[_owner];
    }


    // transfer to and lock it
    function transferAndLock(address _to, uint256 _value, uint _releaseTime) public returns (bool success) {
        require(_to != 0x0);
        require(_value <= balances[msg.sender]);
        require(_value > 0);
        require(_releaseTime > now && _releaseTime <= now + 60*60*24*365*5);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
       
        //if preLock can release 
        uint preRelease = timeRelease[_to];
        if (preRelease <= now && preRelease != 0x0) {
            balances[_to] = balances[_to].add(lockedBalance[_to]);
            lockedBalance[_to] = 0;
        }

        lockedBalance[_to] = lockedBalance[_to].add(_value);
        timeRelease[_to] =  _releaseTime >= timeRelease[_to] ? _releaseTime : timeRelease[_to]; 
        Transfer(msg.sender, _to, _value);
        Lock(_to, _value, _releaseTime);
        return true;
    }


   /**
   * @notice Transfers tokens held by lock.
   */
   function unlock() public constant returns (bool success){
        uint256 amount = lockedBalance[msg.sender];
        require(amount > 0);
        require(now >= timeRelease[msg.sender]);

        balances[msg.sender] = balances[msg.sender].add(amount);
        lockedBalance[msg.sender] = 0;
        timeRelease[msg.sender] = 0;

        Transfer(0x0, msg.sender, amount);
        UnLock(msg.sender, amount);

        return true;

    }


    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public returns (bool success) {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
    
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
        return true;
    }

    // 
    function isSoleout() public constant returns (bool) {
        return (totalSupply >= INITIAL_SUPPLY);
    }


    modifier canMint() {
        require(!isSoleout());
        _;
    } 
    
    /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
    function mintBIX(address _to, uint256 _amount, uint256 _lockAmount, uint _releaseTime) onlyOwner canMint public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        if (_lockAmount > 0) {
            totalSupply = totalSupply.add(_lockAmount);
            lockedBalance[_to] = lockedBalance[_to].add(_lockAmount);
            timeRelease[_to] =  _releaseTime >= timeRelease[_to] ? _releaseTime : timeRelease[_to];            
            Lock(_to, _lockAmount, _releaseTime);
        }

        Transfer(0x0, _to, _amount);
        return true;
    }



}