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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



contract REGUFarm is Ownable {
	
	// APY, base point 1000. If apy 50, it means APY is %5
	uint public apy;

	// LP address
	IERC20 public lpToken;

	// $REGU Token address
	IERC20 public REGUToken;

	// Staking balances
	mapping(address => uint256) public stakingBalances;

	// When user staked their assets
	mapping(address => uint256) public startTime;

	// Reward balances
	mapping(address => uint256) public yieldBalances;

	// If contract not initialized, users can't stake
	bool public isInitialized;

	modifier initialized {
		require(isInitialized, "REGUFarm");
		_;
	}
	
	// For security
	bool public paused;
	
	modifier whenNotPaused {
	    require(paused == false, "REGUFarm: Contract is paused");
	    _;
	}
	

	event Stake(address indexed from, uint256 amount);
	event Unstake(address indexed from, uint256 amount);
	event YieldWithdraw(address indexed to, uint256 amount);

	function stake(uint256 amount) public initialized whenNotPaused {
		require(amount > 0 && lpToken.balanceOf(msg.sender) >= amount, "REGUFarm: You cannot stake that amount of tokens!");
		lpToken.transferFrom(msg.sender, address(this), amount);
		stakingBalances[msg.sender] += amount;
		startTime[msg.sender] = block.timestamp;
		emit Stake(msg.sender, amount);
	}

	function unstake(uint256 amount) public {
		require(stakingBalances[msg.sender] >= amount, "REGUFarm: Nothing to unstake.");
		uint stakeTime = calculateStakeTime(msg.sender);
		
		stakingBalances[msg.sender] -= amount;
		lpToken.transfer(msg.sender, amount);

		if (stakeTime >= 7 days) {
			uint yield_amount = (amount * ((apy * stakeTime) / 365 days)) / 1000;
			yieldBalances[msg.sender] = yield_amount;
		} else {
			// if user unstake his stake under 7 days, he get only %50 of the
			// reward
			uint yield_amount = ((amount * ((apy * stakeTime) / 365 days)) / 1000) / 2;
			yieldBalances[msg.sender] = yield_amount;
		}
		
		if (stakingBalances[msg.sender] == 0) {
		    startTime[msg.sender] = 0;
		} else {
    		startTime[msg.sender] = block.timestamp;
		}
		
		emit Unstake(msg.sender, amount);
	}

	function calculateStakeTime(address user) public view returns(uint) {
	    if(startTime[user] == 0) {
	        return 0;
	    } else {
    		uint end = block.timestamp;
    		uint totalTime = end - startTime[user];
    		return totalTime;
	    }
	}
	
	function calculateRewards(address user) public view returns(uint) {
	    return (stakingBalances[msg.sender] * ((apy * calculateStakeTime(user)) / 365 days)) / 1000;
	}

	function withdrawYield() public {
	    uint userBalance = yieldBalances[msg.sender];
		require(userBalance > 0, "REGUFarm: Nothing to withdraw.");

		yieldBalances[msg.sender] = 0;
		REGUToken.transfer(msg.sender, userBalance);
		emit YieldWithdraw(msg.sender, userBalance);
    }
    
    function initialize(address _lpToken, address _reguToken, uint _apy) public onlyOwner {
        require(!isInitialized, "REGUFarm: Contract already initialized");
        lpToken = IERC20(_lpToken);
        REGUToken = IERC20(_reguToken);
        apy = _apy;
        isInitialized = true;
    }
    
    function setAPY(uint _newAPY) public onlyOwner {
        apy = _newAPY;
    }
    
    function setPause(bool _newState) public onlyOwner {
        paused = _newState;
    }
    
    function setLpToken(address _newToken) public onlyOwner {
        lpToken = IERC20(_newToken);
    }
}
