// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Allowance is Ownable {
    mapping(address => uint256) public allowance;

    event AllowanceChanged(
        address indexed _forWho,
        address indexed _by,
        uint256 _oldAmount,
        uint256 _newAmount
    );

    function addAllowance(address _who, uint256 _amount) public onlyOwner {
        emit AllowanceChanged(_who, msg.sender, allowance[_who], _amount);
        allowance[_who] = _amount;
    }

    function reduceAllowance(address _who, uint256 _amount) internal {
        emit AllowanceChanged(
            _who,
            msg.sender,
            allowance[_who],
            allowance[_who] - _amount
        );
        allowance[_who] -= _amount;
    }
}

contract SimpleWallet is Allowance {
    modifier ownerOrAllowed(uint256 _amount) {
        require(
            owner() == msg.sender || allowance[msg.sender] >= _amount,
            "You are not allowed"
        );
        _;
    }

    constructor() {}

    receive() external payable {}

    fallback() external payable {}

    function withdrawMoney(address _to, uint256 _amount)
        public
        ownerOrAllowed(_amount)
    {
        require(_amount <= address(this).balance, "not enough funds");

        if (owner() != msg.sender) {
            reduceAllowance(msg.sender, _amount);
        }
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send ether");
    }
}
