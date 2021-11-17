// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);
}

contract TokenLock {
	// This is the %10 of the token locker get every month
	uint public s_part;

	// Time period: 1 month
	uint public s_period = 30 days;

	// This will be assign in the constructor
	uint public s_launchTime;

	// Amount of tokens locker withdrawed
	uint public s_withdrawed;

	// Locker
	address public s_locker;

	// Token locked
	IERC20 public s_token;

	constructor(address _locker, address _token) {
	    s_launchTime = block.timestamp;
		s_locker = _locker;
		s_token = IERC20(_token);
	
	    s_part = s_token.balanceOf(_locker) / 10;
	}
	
	function withdraw(uint amount) public {
		require(msg.sender == s_locker);
		uint can_withdraw = canWithdraw();
		require(amount <= can_withdraw, "Lock: You can't withdraw that amount of tokens.");
		require(can_withdraw != 0, "Lock: You can't withdraw tokens now.");
		s_withdrawed += amount;
		s_token.transfer(msg.sender, amount);
	}

	function lockedAmount() public view returns(uint) {
		return s_token.balanceOf(address(this));
	}
	
	function canWithdraw() public view returns (uint) {
	    return (((block.timestamp - s_launchTime) / (s_period)) * s_part) - s_withdrawed;
	}
}
