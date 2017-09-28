pragma solidity ^0.4.11;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './BIXToken.sol';


// Contract for BIX Token sale
contract BIXCrowdsale {
    using SafeMath for uint256;

      // The token being sold
      BIXToken public bixToken;
      
      address public owner;

      // start and end timestamps where investments are allowed (both inclusive)
      uint256 public startTime;
      uint256 public endTime;
      

      uint256 internal constant baseExchangeRate =  1800 ;       //1800 BIX tokens per 1 ETH
      uint256 internal constant earlyExchangeRate = 2000 ;
      uint256 internal constant vipExchangeRate =   2400 ;
      uint256 internal constant vcExchangeRate  =   2500 ;
      uint8  internal constant  DaysForEarlyDay = 11;
      uint256  internal constant vipThrehold = 1000 * (10**18);
            

      //
      event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
      // amount of eth crowded in wei
      uint256 public weiCrowded;


      //constructor
      function BIXCrowdsale(uint256 _startTime, uint256 _endTime, address _wallet) {
            require(_startTime >= now);
            require(_endTime >= _startTime);
            require(_wallet != 0);

            owner = _wallet;
            bixToken = new BIXToken(owner);
            

            startTime = _startTime;
            endTime = _endTime;
      }

      // fallback function can be used to buy tokens
      function () payable {
          buyTokens(msg.sender);
      }

      // low level token purchase function
      function buyTokens(address beneficiary) public payable {
            require(beneficiary != 0x0);
            require(validPurchase());

            uint256 weiAmount = msg.value;
            weiCrowded = weiCrowded.add(weiAmount);

            
            // calculate token amount to be created
            uint256 rRate = rewardRate();
            uint256 rewardBIX = weiAmount.mul(rRate);
            uint256 baseBIX = weiAmount.mul(baseExchangeRate);

            // let it can sale exceed the INITIAL_SUPPLY only at the first time then crowd will end
             uint256 bixAmount = baseBIX.add(rewardBIX);
           
            // the rewardBIX lock in 3 mounthes
            if(rewardBIX > (earlyExchangeRate - baseExchangeRate)) {
                uint releaseTime = startTime + (60 * 60 * 24 * 30 * 3);
                bixToken.mintBIX(beneficiary, baseBIX, rewardBIX, releaseTime);  
            } else {
                bixToken.mintBIX(beneficiary, bixAmount, 0, 0);  
            }
            
            TokenPurchase(msg.sender, beneficiary, weiAmount, bixAmount);
            forwardFunds();           
      }

      /**
       * reward rate for purchase
       */
      function rewardRate() internal constant returns (uint256) {
            
            uint256 rate = baseExchangeRate;

            if (now < startTime) {
                rate = vcExchangeRate;
            } else {
                uint crowdIndex = (now - startTime) / (24 * 60 * 60); 
                if (crowdIndex < DaysForEarlyDay) {
                    rate = earlyExchangeRate;
                } else {
                    rate = baseExchangeRate;
                }

                //vip
                if (msg.value >= vipThrehold) {
                    rate = vipExchangeRate;
                }
            }
            return rate - baseExchangeRate;
        
      }



      // send ether to the fund collection wallet
      function forwardFunds() internal {
            owner.transfer(msg.value);
      }

      // @return true if the transaction can buy tokens
      function validPurchase() internal constant returns (bool) {
            bool nonZeroPurchase = msg.value != 0;
            bool noEnd = !hasEnded();
            
            return  nonZeroPurchase && noEnd;
      }

      // @return true if crowdsale event has ended
      function hasEnded() public constant returns (bool) {
            return (now > endTime) || bixToken.isSoleout(); 
      }


}