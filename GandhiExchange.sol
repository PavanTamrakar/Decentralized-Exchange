// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {

    address public GandhiMoneyTokenAddress;

    constructor(address _GandhiMoneytoken) ERC20("GandhiMoney LP Token", "CDLP") {
        require(_GandhiMoneytoken != address(0), "Token address passed is a null address");
        gandhiMoneyTokenAddress = _GandhiMoneytoken;
    }
    
    function getReserve() public view returns (uint) {
        return ERC20(gandhiMoneyTokenAddress).balanceOf(address(this));
   }
   
   function addLiquidity(uint _amount) public payable returns (uint) {
       uint liquidity;
       uint ethBalance = address(this).balance;
       uint gandhiMoneyTokenReserve = getReserve();
       ERC20 gandhiMoneyToken = ERC20(gandhiMoneyTokenAddress);
   
       if(gandhiMoneyTokenReserve == 0) {
           gandhiMoneyToken.transferFrom(msg.sender, address(this), _amount);
           liquidity = ethBalance;
           _mint(msg.sender, liquidity);
   } else {
        uint ethReserve =  ethBalance - msg.value;
        uint gandhiMoneyTokenAmount = (msg.value * gandhiMoneyTokenReserve)/(ethReserve);
        require(_amount >= gandhiMoneyTokenAmount, "Amount of tokens sent is less than the minimum tokens required");

        gandhiMoneyToken.transferFrom(msg.sender, address(this), gandhiMoneyTokenAmount);
        liquidity = (totalSupply() * msg.value)/ ethReserve;
        _mint(msg.sender, liquidity);
    }
     return liquidity;
     
    function removeLiquidity(uint _amount) public returns (uint , uint) {
        require(_amount > 0, "_amount should be greater than zero");
        uint ethReserve = address(this).balance;
        uint _totalSupply = totalSupply();
        uint ethAmount = (ethReserve * _amount)/ _totalSupply;
  
        uint gandhiMoneyTokenAmount = (getReserve() * _amount)/ _totalSupply;
 
        _burn(msg.sender, _amount);
    
        payable(msg.sender).transfer(ethAmount);
    
        ERC20(gandhiMoneyTokenAddress).transfer(msg.sender, gandhiMoneyTokenAmount);
        return (ethAmount, gandhiMoneyTokenAmount);
    }
    
    function getAmountOfTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
        ) public pure returns (uint256) {
            require(inputReserve > 0 && outputReserve > 0, "invalid reserves");
    
        uint256 inputAmountWithFee = inputAmount * 99;
    
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;
            return numerator / denominator;
    }
    function ethTogandhiMoneyToken(uint _minTokens) public payable {
        uint256 tokenReserve = getReserve();
        uint256 tokensBought = getAmountOfTokens(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
    );

        require(tokensBought >= _minTokens, "insufficient output amount");
   
        ERC20(gandhiMoneyTokenAddress).transfer(msg.sender, tokensBought);
    }
    function gandhiMoneyTokenToEth(uint _tokensSold, uint _minEth) public {
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmountOfTokens(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );
        require(ethBought >= _minEth, "insufficient output amount");

        ERC20(gandhiMoneyTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokensSold
        );
    
        payable(msg.sender).transfer(ethBought);
}
