// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Allowance.sol";

contract SimpleWallet is Allowance {
    event MoneySent(address indexed _beneficiary, uint256 _amount);
    event MoneyReceived(address indexed _from, uint256 _amount);

    modifier ownerOrAllowed(uint256 _amount) {
        require(
            owner() == _msgSender() || allowance[_msgSender()] >= _amount,
            "You are not allowed"
        );
        _;
    }

    constructor() {}

    receive() external payable {
        emit MoneyReceived(_msgSender(), msg.value);
    }

    fallback() external payable {}

    function withdrawMoney(address _to, uint256 _amount)
        public
        ownerOrAllowed(_amount)
    {
        require(_amount <= address(this).balance, "not enough funds");

        if (owner() != _msgSender()) {
            reduceAllowance(_msgSender(), _amount);
        }
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send ether");
        emit MoneySent(_to, _amount);
    }

    function renounceOwnership() public view override onlyOwner {
        revert("Can't renounce ownership here");
    }
}
