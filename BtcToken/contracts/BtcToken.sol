// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

/// @title A title that should describe the contract/interface
/// @author Jeff
/// @notice BtcToken
/// @dev 
contract BtcToken {
    //代币名称
    string private _name;
    // 代币符号
    string private _symbol;
    //小数点位数
    uint8 _decimals = 18;
    // 代币总供应量
    uint256 private _totalSupply;
    // 账户余额
    mapping(address => uint256) private _balances;
    // 授权额度 拥有者 => (被授权者 => 授权额度)
    mapping(address => mapping(address => uint256)) private _allowances;
    // 合约拥有者
    address public owner;

    //转账事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    //授权事件
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    //构造函数
    constructor(string memory name, string memory symbol, uint256 totalSupply) {
        _name = name;
        _symbol = symbol;
        _totalSupply = totalSupply;
        owner = msg.sender;
    }

    // 返回代币名称
    function name() public view returns (string memory) {
        return _name;
    }

    //返回代币符号
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // 返回代币小数点位数
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    //返回代币总供应量
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    //返回指定地址的代币余额
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    //返回指定地址允许另一地址支配的代币数量
    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner can do this");
        _;
    }

    //允许第三方账户支配自己一定数量的代币
    function approve(address spender, uint256 amount) public {
        //授权额度
        require(amount > 0, "amount must more than 0");
        // 被授权人地址校验
        require(spender != address(0), "spender address is invalid");

        //余额不足
        require(_balances[msg.sender] > amount, "You have no enough money");

        //跟新授权额度
        _allowances[msg.sender][spender] = amount;
        //触发事件
        emit Approval(msg.sender, spender, amount);
    }

    //从调用者地址向另一个地址转移代币
    function transfer(address to, uint256 amount) public {
        require(amount > 0, "amount must more than 0");
        // 被授权人地址校验
        require(to != address(0), "to address is invalid");
        //余额检查
        require(_balances[msg.sender] > amount, "You have no enough money");
        //更新余额
        _balances[msg.sender] -= amount;
        _balances[to] -= amount;

        //调用转账事件
        emit Transfer(msg.sender, to, amount);
    }

    //从一个地址向另一个地址转移代币（需要事先授权）
    function transferFrom(address from, address to, uint256 amount) public {
        // 地址校验
        require(from != address(0), "from address is invalid");
        // 地址校验
        require(to != address(0), "to address is invalid");
        require(amount > 0, "amount must more than 0");
        uint256 _allowance = _allowances[from][msg.sender];
        //检查授权额度是否足够
        require(
            _allowance >= amount,
            "from account have no enough money"
        );

        //授权额度变更
        //非无限授权时，减去额度
        if (_allowance != type(uint256).max) {
            _allowances[from][msg.sender] -= amount;
        }

        //余额变更
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    //增发代币 给某个账户增发代码
    function mint(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "account address is invalid");
        require(amount > 0, "amount must more than 0");
        _balances[account] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), account, amount);
    }

    //销毁指定地址的代币数量
    function burn(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "account address is invalid");
        require(amount > 0, "amount must more than 0");
        require(
            _balances[account] >= amount,
            "amount account has no enough money"
        );

        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
}
