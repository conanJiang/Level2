// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MultisigWallet {
    //多签持有人数组
    address[] public owner;
    //是否是多签持有人
    mapping(address => bool) public isOwner;
    //多签持有人数量
    uint256 public ownerCount;
    //多签执行门槛
    uint256 public threshold;
    //成功数量
    uint256 public nonce;

    event ExecTransactionSuccess(bytes32 dataHash);
    event ExecTransactionFail(bytes32 dataHash);

    receive() external payable {

     }

    constructor(address[] memory _owner, uint256 _threshold) {
        _setupOnwers(_owner, _threshold);
    }

    /**
        初始化多签信息 (私有！)
    **/
    function _setupOnwers(address[] memory _owners, uint256 _threshold)
        internal
    {
        require(_threshold > 0, "threshold must be greater than or equal to 1");
        require(
            _owners.length >= _threshold,
            "ownerCount must be greater than or equal to threshold"
        );
        require(_owners.length > 1, "ownerCount must be greater than 1");
        for (uint256 i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0), "owner is zero");
            require(!isOwner[_owners[i]], "owner is exists");
            isOwner[_owners[i]] = true;
            ownerCount++;
        }
        owner = _owners;
        threshold = _threshold;
    }

    //将对应序号上的签名分割出r s v
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }

    /**
        创建交易hash
    **/
    function encodeTransactionData(
        address to,
        uint256 value,
        bytes memory data,
        uint256 _nonce,
        uint256 chainid
    ) public pure returns (bytes32) {
        bytes32 safeTxHash = keccak256(
            abi.encode(to, value, data, _nonce, chainid)
        );
        return safeTxHash;
    }

    //执行交易 传入交易信息 + 签名信息
    function execTransaction(
        address to,
        uint256 value,
        bytes memory data,
        bytes memory signatures
    ) public payable virtual returns (bool success) {
        bytes32 dataHash = encodeTransactionData(
            to,
            value,
            data,
            nonce,
            block.chainid
        );
        nonce++;
        checkSignatures(dataHash, signatures);
        (success, ) = to.call{value: value}(data);
        require(success, "checkSignatures failed");
        if (success) {
            emit ExecTransactionSuccess(dataHash);
        } else {
            emit ExecTransactionFail(dataHash);
        }
    }

    //校验多签签名是否有效
    function checkSignatures(bytes32 dataHash, bytes memory signatures)
        public
        view
    {
        uint256 _threshold = threshold;
        require(_threshold > 0, "threshold must be greater than or equal to 1");

        //打包的签名长度至少满足多签门槛
        require(
            signatures.length >= _threshold * 65,
            "signatures length is invalid"
        );

        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        for (uint256 i = 0; i < _threshold; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            //ECRecover获取公钥
            currentOwner = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        dataHash
                    )
                ),
                v,
                r,
                s
            );
            require(
                currentOwner > lastOwner && isOwner[currentOwner],
                "signatures is invalid"
            );
            lastOwner = currentOwner;
        }
    }
}
