// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";


contract SignatureNFT is ERC721{

    //签名地址
    address immutable public signer;
    //已经mint的地址
    mapping(address => bool) public mintedAddress;

    // 构造函数，初始化NFT合集的名称、代号、签名地址
    constructor(string memory _name,string memory _symbol,address _signer)
    ERC721(_name,_symbol)
    {
        signer = _signer;
    }

    // 利用ECDSA验证签名并mint
    function mint(address _account,uint256 _tokenId,bytes memory _signature) external {
        bytes32 _msgHash = getMessageHash(_account, _tokenId);
        bytes32 _ethSignedMessageHash =  MessageHashUtils.toEthSignedMessageHash(_msgHash);
        require(verify(_ethSignedMessageHash,_signature),"Invalid signature");
        require(!mintedAddress[_account], "Already minted!");
        // mint
        _mint(_account, _tokenId); 
         // 记录mint过的地址
         mintedAddress[_account] = true;


    }

    /**
     * @dev 返回 以太坊签名消息
     * `hash`：消息
     * 遵从以太坊签名标准：https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * 以及`EIP191`:https://eips.ethereum.org/EIPS/eip-191`
     * 添加"\x19Ethereum Signed Message:\n32"字段，防止签名的是可执行交易。
     */
    function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        // 哈希的长度为32
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }


    /*
     * 将mint地址（address类型）和tokenId（uint256类型）拼成消息msgHash
     * _account: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
     * _tokenId: 0
     * 对应的消息: 0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c
     */
    function getMessageHash(address _account, uint256 _tokenId) public pure returns(bytes32){
        return keccak256(abi.encodePacked(_account, _tokenId));
    }


     // ECDSA验证，调用ECDSA库的verify()函数
    function verify(bytes32 _msgHash, bytes memory _signature)
    public view returns (bool)
    {
        address recovered = ECDSA.recover(_msgHash, _signature);
    return recovered == signer;
    }

    /**
        学习过程记录：
            1.先用getMessageHash给指定账户A和token生成消息
            2.用主账户对上述消息进行签名
            3.创建signatureNFT合约，构造函数传入主账户的公钥地址
            4.使用mint进行验证，传入被发放账户A、token、已签名的消息，通过ECDSA.recover算出公钥，与构造方法传入的公钥对比，实现验证

    **/


}