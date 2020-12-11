// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";

contract CoinslootSale {
  using SafeMath for uint256;

  // The token being sold
  ERC20 public token;

  // Multisig smart contract address to which funds will be sent
  address payable public wallet = 0x74C1F04AeCD63aD1ec7cB8d8eA18EcF530B41061;

  address public owner;

  // How many token units a buyer gets per wei
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  constructor(uint256 _rate, ERC20 _token) {
    owner = msg.sender;
    rate = _rate;
    token = _token;
  }

  function getRate() public view returns (uint256) {
    return rate;
  }

  function changeRate(uint256 _newRate) public {
    require(msg.sender == owner);
    rate = _newRate;
  }

  function withdrawTokensToOwner(uint256 _amount) public {
    require(msg.sender == owner);
    _deliverTokens(owner, _amount);
  }

  receive() external payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address _beneficiary) public payable {
    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    uint256 tokens = _getTokenAmount(weiAmount);

    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal pure {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {}

  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {}

  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256){
    assert(rate != 0);
    return (_weiAmount / rate) * 10**18;
  }

  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}
