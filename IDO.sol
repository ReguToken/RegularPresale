// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

contract REGUIDO {
    string public constant NAME = "Regular Presale";
    string public projectName;                  // Project name defined by ido owner
    uint256 public maxCap;                      // Max cap in BUSD
    uint256 public saleStartTime;               // Sale start time
    uint256 public saleEndTime;                 // Sale end time
    uint256 public totalBusdReceivedInAllTier;  // Total busd received
    address public admin;                       // admin will manage this contract
    uint public price;                          // price of 1 token

    // those addresses can buy tokens after saleEndTime, if there are some tokens
    mapping(address => bool) public whitelist;

    // users in whitelist can buy tokens max that amount of busd
    uint256 public afterSaleMaxAmount;

    // balance of after sale purchases
    mapping(address => uint256) public afterSaleBalance;

    address busdAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    modifier onlyAdmin() {
        require(msg.sender == admin, "REGUIDO: You are not the admin!");
        _;
    }

    // Total buys by tiers
    uint256 public totalBusdInTierOne;
    uint256 public totalBusdInTierTwo;
    uint256 public totalBusdInTierThree;
    uint256 public totalBusdInTierFour;
    uint256 public totalBusdInTierFive;
    uint256 public totalBusdInTierSix;

    // Tier max caps
    uint256 public maxCapInTierOne;
    uint256 public maxCapInTierTwo;
    uint256 public maxCapInTierThree;
    uint256 public maxCapInTierFour;
    uint256 public maxCapInTierFive;
    uint256 public maxCapInTierSix;

    // Tiers
    mapping(address => bool) public tierOneAddresses;
    mapping(address => bool) public tierTwoAddresses;
    mapping(address => bool) public tierThreeAddresses;
    mapping(address => bool) public tierFourAddresses;
    mapping(address => bool) public tierFiveAddresses;
    mapping(address => bool) public tierSixAddresses;

    //  Max allocation per tiers
    uint256 public maxAllocPerUserTierOne;
    uint256 public maxAllocPerUserTierTwo;
    uint256 public maxAllocPerUserTierThree;
    uint256 public maxAllocPerUserTierFour;
    uint256 public maxAllocPerUserTierFive;
    uint256 public maxAllocPerUserTierSix;

    // User balances by tiers
    mapping(address => uint256) public buyInOneTier;
    mapping(address => uint256) public buyInTwoTier;
    mapping(address => uint256) public buyInThreeTier;
    mapping(address => uint256) public buyInFourTier;
    mapping(address => uint256) public buyInFiveTier;
    mapping(address => uint256) public buyInSixTier;

    constructor(
        address _admin,
        string memory _projectName,
        uint _price,
        uint256 _maxCap,
        uint256 _saleStartTime,
        uint256 _saleEndTime,
        uint256[] memory _tierMaxCaps,
        uint256[] memory _tierMaxAllocs,
        uint256 _afterSaleMaxAmount
    ) {
        admin = _admin;
        projectName = _projectName;
        price = _price;
        maxCap = _maxCap;
        saleStartTime = _saleStartTime;
        saleEndTime = _saleEndTime;
        maxCapInTierOne = _tierMaxCaps[0];
        maxCapInTierTwo = _tierMaxCaps[1];
        maxCapInTierThree = _tierMaxCaps[2];
        maxCapInTierFour = _tierMaxCaps[3];
        maxCapInTierFive = _tierMaxCaps[4];
        maxCapInTierSix = _tierMaxCaps[5];
        maxAllocPerUserTierOne = _tierMaxAllocs[0];
        maxAllocPerUserTierTwo = _tierMaxAllocs[1];
        maxAllocPerUserTierThree = _tierMaxAllocs[2];
        maxAllocPerUserTierFour = _tierMaxAllocs[3];
        maxAllocPerUserTierFive = _tierMaxAllocs[4];
        maxAllocPerUserTierSix = _tierMaxAllocs[5];
        afterSaleMaxAmount = _afterSaleMaxAmount;
    }

    function updateTiersMaxAllocs(
        uint256 _tierOneMaxAlloc,
        uint256 _tierTwoMaxAlloc,
        uint256 _tierThreeMaxAlloc,
        uint256 _tierFourMaxAlloc,
        uint256 _tierFiveMaxAlloc,
        uint256 _tierSixMaxAlloc
    ) public onlyAdmin {
        maxAllocPerUserTierOne = _tierOneMaxAlloc;
        maxAllocPerUserTierTwo = _tierTwoMaxAlloc;
        maxAllocPerUserTierThree = _tierThreeMaxAlloc;
        maxAllocPerUserTierFour = _tierFourMaxAlloc;
        maxAllocPerUserTierFive = _tierFiveMaxAlloc;
        maxAllocPerUserTierSix = _tierSixMaxAlloc;
    }

    function updateTiersMaxCap(
        uint256 _tierOneMaxCap,
        uint256 _tierTwoMaxCap,
        uint256 _tierThreeMaxCap,
        uint256 _tierFourMaxCap,
        uint256 _tierFiveMaxCap,
        uint256 _tierSixMaxCap
    ) public onlyAdmin {
        maxCapInTierOne = _tierOneMaxCap;
        maxCapInTierTwo = _tierTwoMaxCap;
        maxCapInTierThree = _tierThreeMaxCap;
        maxCapInTierFour = _tierFourMaxCap;
        maxCapInTierFive = _tierFiveMaxCap;
        maxCapInTierSix = _tierSixMaxCap;
    }

	function changeAdmin(address _newAdmin) public onlyAdmin {
		admin = _newAdmin;
	}

    function withdrawToken(address _token, address _to, uint256 _amount) public onlyAdmin {
        require(block.timestamp > saleEndTime, "REGUIDO: Sale is not over!");
        IERC20(_token).transfer(_to, _amount);
    }

    function addTierOne(address[] calldata _newUsers) external onlyAdmin {
        for (uint256 i = 0; i < _newUsers.length; i++) {
            tierOneAddresses[_newUsers[i]] = true;
        }
    }

    function addTierTwo(address[] calldata _newUsers) external onlyAdmin {
        for (uint256 i = 0; i < _newUsers.length; i++) {
            tierTwoAddresses[_newUsers[i]] = true;
        }
    }

    function addTierThree(address[] calldata _newUsers)
        external
        onlyAdmin
    {
        for (uint256 i = 0; i < _newUsers.length; i++) {
            tierThreeAddresses[_newUsers[i]] = true;
        }
    }

    function addTierFour(address[] calldata _newUsers) external onlyAdmin {
        for (uint256 i = 0; i < _newUsers.length; i++) {
            tierFourAddresses[_newUsers[i]] = true;
        }
    }

    function addTierFive(address[] calldata _newUsers) external onlyAdmin {
        for (uint256 i = 0; i < _newUsers.length; i++) {
            tierFiveAddresses[_newUsers[i]] = true;
        }
    }

    function addTierSix(address[] calldata _newUsers) external onlyAdmin {
        for (uint256 i = 0; i < _newUsers.length; i++) {
            tierSixAddresses[_newUsers[i]] = true;
        }
    }

    function addWhiteList(address[] calldata _newUsers) external onlyAdmin {
        for (uint256 i = 0; i < _newUsers.length; i++) {
            whitelist[_newUsers[i]] = true;
        }
    }

    function buyAfterSale(uint256 _busdAmount) external {
        require(block.timestamp > saleEndTime, "REGUIDO: Sale is not over yet!");
        require(afterSaleBalance[msg.sender] + _busdAmount <= afterSaleMaxAmount, "REGUIDO: Purchase would exceed your max sale amount after sale!");
        require(totalBusdReceivedInAllTier + _busdAmount <= maxCap, "REGUIDO: Purchase would exceed max cap!");
        require(whitelist[msg.sender], "REGUIDO: You are not in the whitelist!");

        // try to get busds from user
        IERC20(busdAddress).transferFrom(
            msg.sender,
            address(this),
            _busdAmount
        );

        afterSaleBalance[msg.sender] += _busdAmount;
        totalBusdReceivedInAllTier += _busdAmount;
        
    }

    function buyTokens(uint256 _busdAmount) external {
        require(
            block.timestamp > saleStartTime,
            "REGUIDO: Sale is not started yet!"
        );
        require(block.timestamp < saleEndTime, "REGUIDO: Sale is closed!");
        require(
            totalBusdReceivedInAllTier + _busdAmount <= maxCap,
            "REGUIDO: Purchase would exceed max cap!"
        );

        // try to get busds from user
        IERC20(busdAddress).transferFrom(
            msg.sender,
            address(this),
            _busdAmount
        );

        if (tierOneAddresses[msg.sender]) {
            require(
                totalBusdInTierOne + _busdAmount <= maxCapInTierOne,
                "REGUIDO: Purchase would exceed tier one max cap!"
            );
            require(
                buyInOneTier[msg.sender] + _busdAmount <=
                    maxAllocPerUserTierOne,
                "REGUIDO: You are investing more than your tier-1 limit!"
            );
            buyInOneTier[msg.sender] += _busdAmount;
            totalBusdReceivedInAllTier += _busdAmount;
            totalBusdInTierOne += _busdAmount;
        } else if (tierTwoAddresses[msg.sender]) {
            require(
                totalBusdInTierTwo + _busdAmount <= maxCapInTierTwo,
                "REGUIDO: Purchase would exceed tier two max cap!"
            );
            require(
                buyInTwoTier[msg.sender] + _busdAmount <=
                    maxAllocPerUserTierTwo,
                "REGUIDO: You are investing more than your tier-2 limit!"
            );
            buyInTwoTier[msg.sender] += _busdAmount;
            totalBusdReceivedInAllTier += _busdAmount;
            totalBusdInTierTwo += _busdAmount;
        } else if (tierThreeAddresses[msg.sender]) {
            require(
                totalBusdInTierThree + _busdAmount <= maxCapInTierThree,
                "REGUIDO: Purchase would exceed tier three max cap!"
            );
            require(
                buyInThreeTier[msg.sender] + _busdAmount <=
                    maxAllocPerUserTierThree,
                "REGUIDO: You are investing more than your tier-3 limit!"
            );
            buyInThreeTier[msg.sender] += _busdAmount;
            totalBusdReceivedInAllTier += _busdAmount;
            totalBusdInTierThree += _busdAmount;
        } else if (tierFourAddresses[msg.sender]) {
            require(
                totalBusdInTierFour + _busdAmount <= maxCapInTierFour,
                "REGUIDO: Purchase would exceed tier four max cap!"
            );
            require(
                buyInFourTier[msg.sender] + _busdAmount <=
                    maxAllocPerUserTierFour,
                "REGUIDO: You are investing more than your tier-4 limit!"
            );
            buyInFourTier[msg.sender] += _busdAmount;
            totalBusdReceivedInAllTier += _busdAmount;
            totalBusdInTierFour += _busdAmount;
        } else if (tierFiveAddresses[msg.sender]) {
            require(
                totalBusdInTierFive + _busdAmount <= maxCapInTierFive,
                "REGUIDO: Purchase would exceed tier five max cap!"
            );
            require(
                buyInFiveTier[msg.sender] + _busdAmount <=
                    maxAllocPerUserTierFive,
                "REGUIDO: You are investing more than your tier-5 limit!"
            );
            buyInFiveTier[msg.sender] += _busdAmount;
            totalBusdReceivedInAllTier += _busdAmount;
            totalBusdInTierFive += _busdAmount;
        } else if (tierSixAddresses[msg.sender]) {
            require(
                totalBusdInTierSix + _busdAmount <= maxCapInTierSix,
                "REGUIDO: Purchase would exceed tier six max cap!"
            );
            require(
                buyInSixTier[msg.sender] + _busdAmount <=
                    maxAllocPerUserTierSix,
                "REGUIDO: You are investing more than your tier-6 limit!"
            );
            buyInSixTier[msg.sender] += _busdAmount;
            totalBusdReceivedInAllTier += _busdAmount;
            totalBusdInTierSix += _busdAmount;
        } else {
            revert("REGUIDO: You are not in any tier!");
        }
    }
}

contract REGUIDOFactory is Ownable {
    address[] public idosOnProgress;
    address[] public idosFinished;

    function createIDO(
        string memory _projectName,
        uint _price,
        uint256 _maxCap,
        uint256 _saleStartTime,
        uint256 _saleEndTime,
        uint256[] memory _tierMaxCaps,
        uint256[] memory _tierMaxAllocs,
        uint256 _afterSaleMaxAmount
    ) public onlyOwner returns(address) {
        address newIdo = address(
            new REGUIDO(
                msg.sender,
                _projectName,
                _price,
                _maxCap,
                _saleStartTime,
                _saleEndTime,
                _tierMaxCaps,
                _tierMaxAllocs,
                _afterSaleMaxAmount
            )
        );

        idosOnProgress.push(newIdo);
        return newIdo;
    }

    function finishIDO(address _idoForFinish) public onlyOwner {
        for (uint256 i = 0; i < idosOnProgress.length; i++) {
            if (idosOnProgress[i] == _idoForFinish) {
                idosFinished.push(idosOnProgress[i]);
                idosOnProgress[i] = idosOnProgress[idosOnProgress.length - 1];
                idosOnProgress.pop();
            }
        }
    }

    function getAllInProgressIDOs() public view returns(address[] memory) {
        return idosOnProgress;
    }

    function getAllFinishedIDOs() public view returns(address[] memory) {
        return idosFinished;
    }
}
