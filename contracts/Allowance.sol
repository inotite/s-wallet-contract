// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Allowance is Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) public allowance;

    event AllowanceChanged(
        address indexed _forWho,
        address indexed _by,
        uint256 _oldAmount,
        uint256 _newAmount
    );

    function addAllowance(address _who, uint256 _amount) public onlyOwner {
        emit AllowanceChanged(_who, _msgSender(), allowance[_who], _amount);
        allowance[_who] = _amount;
    }

    function reduceAllowance(address _who, uint256 _amount) internal {
        emit AllowanceChanged(
            _who,
            _msgSender(),
            allowance[_who],
            allowance[_who].sub(_amount)
        );
        allowance[_who] = allowance[_who].sub(_amount);
    }
}
