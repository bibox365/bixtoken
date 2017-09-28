var BIXCrowdsale = artifacts.require("./BIXCrowdsale.sol");

var wallet = '0x37fdc23c71d51423a5bc4396e1c5337f51c58e88';
var start =  new Date('2017-10-01T02:00:00Z').getTime()/1000;
var end = new Date('2017-10-31T15:59:59Z').getTime()/1000;

module.exports = function(deployer) {
  deployer.deploy(BIXCrowdsale, start, end, wallet);
};
