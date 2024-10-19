// SPDX-License-Identifier: MIT 

pragma solidity >=0.7.0 <0.9.0;

contract Verification {
    constructor() { owner = msg.sender; }
    uint16 public count_Exporters = 0;
    uint16 public count_hashes = 0;
    address public owner;

    struct Record {
        uint blockNumber; 
        uint minetime; 
        string info;
        string ipfs_hash;
    }

    struct Exporter_Record {
        uint blockNumber;
        string info;
    }

    mapping(bytes32 => Record) private docHashes;
    mapping(address => Exporter_Record) private Exporters;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Invalid address");
        _;
    }

    modifier authorised_Exporter(bytes32 _doc) {
        require(
            keccak256(abi.encodePacked(Exporters[msg.sender].info)) ==
            keccak256(abi.encodePacked(docHashes[_doc].info)),
            "Caller is not authorised to edit this document"
        );
        _;
    }

    modifier canAddHash() {
        require(Exporters[msg.sender].blockNumber != 0, "Caller not authorised to add documents");
        _;
    }

    function add_Exporter(address _add, string calldata _info) external onlyOwner { 
        require(Exporters[_add].blockNumber == 0, "Exporter already exists");

        Exporters[_add].blockNumber = block.number;
        Exporters[_add].info = _info;
        ++count_Exporters;
    }

    function delete_Exporter(address _add) external onlyOwner {
        require(Exporters[_add].blockNumber != 0, "Exporter does not exist");

        Exporters[_add].blockNumber = 0;
        Exporters[_add].info = "";
        --count_Exporters;
    }

    function alter_Exporter(address _add, string calldata _newInfo) external onlyOwner { 
        require(Exporters[_add].blockNumber != 0, "Exporter does not exist");
        Exporters[_add].info = _newInfo;
    }

    function changeOwner(address _newOwner) external onlyOwner validAddress(_newOwner) {
        owner = _newOwner;
    }

    function isOwner() external view returns (bool) {
        return msg.sender == owner;
    }

    event addHash(address indexed _exporter, string _ipfsHash);

    function addDocHash(bytes32 hash, string calldata _ipfs) external canAddHash {
        require(docHashes[hash].blockNumber == 0 && docHashes[hash].minetime == 0, "Document already exists");
        Record memory newRecord = Record(block.number, block.timestamp, Exporters[msg.sender].info, _ipfs);
        docHashes[hash] = newRecord; 
        ++count_hashes;
        emit addHash(msg.sender, _ipfs);
    }

    function findDocHash(bytes32 _hash) external view returns (uint, uint, string memory, string memory) {
        return (
            docHashes[_hash].blockNumber,
            docHashes[_hash].minetime,
            docHashes[_hash].info,
            docHashes[_hash].ipfs_hash
        );
    }

    function deleteHash(bytes32 _hash) external authorised_Exporter(_hash) canAddHash {
        require(docHashes[_hash].minetime != 0, "Document does not exist");
        docHashes[_hash].blockNumber = 0;
        docHashes[_hash].minetime = 0;
        --count_hashes;
    }

    function getExporterInfo(address _add) external view returns (string memory) {
        return Exporters[_add].info;
    }
}
