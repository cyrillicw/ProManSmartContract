const ProMan = artifacts.require("./proman.sol");

module.exports = function(deployer) {
  deployer.deploy(ProMan);
};
