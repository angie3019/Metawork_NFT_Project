//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC1155, Ownable {
    string public name;
    string public symbol;
    string public baseURI;
    
    
    mapping(uint256 =>mapping(address => bool)) allowedList;
    mapping(uint256 => Token) public tokenIdToToken;
    mapping (uint256 => string) private _tokenUris;

    using Counters for Counters.Counter;  // using counter for auto-incrementing the token id's
    Counters.Counter private tokenId;

    // Each token represent different cohort of buildspace
    struct Token {
        uint256 id;
        string name;
        bool limited;
        uint128 tokenLimit;
        uint128 tokenMinted;
        bool isAllowed;
        bool isAllowedList;
        bool exists;
        bool allowTransfer;
     }

    modifier checkMinting(uint tokenID) {

        require(tokenIdToToken[tokenID].exists,"Token doesn't exist");
        if (tokenIdToToken[tokenID].limited) {
            require (
                tokenIdToToken[tokenID].tokenMinted < tokenIdToToken[tokenID].tokenLimit,
                "Max tokens issued"
            );
        }
        _;
    }

    modifier checkMintingBatch(uint toLength,uint tokenID) {

        require(tokenIdToToken[tokenID].exists,"Token doesn't exist");
        if (tokenIdToToken[tokenID].limited) {
            require (
                tokenIdToToken[tokenID].tokenMinted + toLength<= tokenIdToToken[tokenID].tokenLimit,
                "Token limit exceeding max limit"
            );
        }
        _;
    }

    modifier checkTransferAllowed(uint tokenID){
        require(tokenIdToToken[tokenID].allowTransfer,"Transfer not allowed for this token");
        _;
    }

    modifier checkTransferAllowedBatch(uint[] memory tokenIDs){
        for(uint i=0;i<tokenIDs.length;i++){
            require(tokenIdToToken[tokenIDs[i]].allowTransfer,"Transfer not allowed for this token");

        }
        _;
    }

    constructor(string memory _name, string memory _symbol,string memory _baseURI) ERC1155('') {
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
        
    }

   


    // Create token 
    function createToken(string memory _name, bool _limited, uint128 _limit,bool _allowed, bool _allowedList,bool _allowTransfer,string memory _uri) external  onlyOwner  {
      
        // ID, Name, Limited, Limit, Minted,external minting allowed,minting allowed by list,exists,transfer allowed
       
       tokenId.increment();
       require(!tokenIdToToken[tokenId.current()].exists,"Token already exists");
       Token memory token = Token(tokenId.current(), _name, _limited, _limit, 0,_allowed, _allowedList,true,_allowTransfer);
       setTokenUri(_uri, tokenId.current());
       tokenIdToToken[tokenId.current()] = token;
       mintTokenItem(msg.sender, tokenId.current());
    }
    

    function mintTokenItem(address to,uint tokenID) public onlyOwner checkMinting(tokenID)  {       
        _mint(to, tokenID, 1, '');
        tokenIdToToken[tokenID].tokenMinted += 1;
        
    }

    function mintTokenItemOther(address to,uint tokenID) public checkMinting(tokenID) {
        
       
        require(balanceOf(to,tokenID)==0,"Token can only be minted once");
       // Either the sender can be owner or belong to an allowed address for this token 
        require((tokenIdToToken[tokenID].isAllowed &&  !tokenIdToToken[tokenID].isAllowedList)|| (tokenIdToToken[tokenID].isAllowed && tokenIdToToken[tokenID].isAllowedList && allowedList[tokenID][to]) ,"User is not allowed to mint this token");
        _mint(to, tokenID, 1, '');
        tokenIdToToken[tokenID].tokenMinted += 1;
       
      //  if(tokenIdToToken[tokenID].isAllowedList)
            //allowedList[tokenID][msg.sender] = false;
        
     }


    function batchMintTokenItem(address[] memory to,uint tokenID) public onlyOwner checkMintingBatch(to.length,tokenID)  {
   
        for (uint i = 0; i < to.length; i++) {
           mintTokenItem(to[i],tokenID);
        }
    }
    function batchMintTokenItemOther(address[] memory to,uint tokenID) public  checkMintingBatch(to.length,tokenID) {
   
        for (uint i = 0; i < to.length; i++) {
            mintTokenItemOther(to[i],tokenID);
        }
    }

    function safeTransferFrom(address from,address to,uint256 id,uint256 amount,bytes memory data) public  override  checkTransferAllowed(id){
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(address from,address to,uint256[] memory ids,uint256[] memory amounts,bytes memory data) public  override checkTransferAllowedBatch(ids){
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function uri(uint256 id) override public view returns (string memory) {
        return(_tokenUris[id]);
    }
    
   
    function getTokenName(uint256 _tokenId) public view returns (string memory) {
        return tokenIdToToken[_tokenId].name;
    }

    function getTokenLimited(uint256 _tokenId) public view returns (bool) {
        return tokenIdToToken[_tokenId].limited;
    }

    function getTokenLimit(uint256 _tokenId) public view returns (uint128) {
        return tokenIdToToken[_tokenId].tokenLimit;
    }

    function getTokenMinted(uint256 _tokenId) public view returns (uint128) {
        return tokenIdToToken[_tokenId].tokenMinted;
    }

    function isAllowed(uint256 _tokenId) public view returns (bool) {
        return tokenIdToToken[_tokenId].isAllowed;
    } 

    function isAllowedList(uint256 _tokenId) public view returns (bool) {
        return tokenIdToToken[_tokenId].isAllowedList;
    }

    function isExists(uint256 _tokenId) public view returns (bool) {
        return tokenIdToToken[_tokenId].exists;
    }

    function isAllowedTransfer(uint256 _tokenId) public view returns (bool) {
        return tokenIdToToken[_tokenId].allowTransfer;
    }

    function getAllowedList(uint256 _tokenId,address user) public view returns (bool) {
        return allowedList[_tokenId][user];
    }

    // Setter functions
    function setTokenUri(string memory _uri,uint256 id) public onlyOwner {
        _tokenUris[id] = _uri; 
    }

    function setTokenisLimited(uint tokenID,bool _isLimited) public  onlyOwner {
        tokenIdToToken[tokenID].limited= _isLimited;
    }

    function setTokenLimit(uint tokenID,uint128 limit) public  onlyOwner {
        tokenIdToToken[tokenID].tokenLimit = limit;
    }

      
    function setTokenisAllowed(uint tokenID,bool _isAllowed) public  onlyOwner {
        tokenIdToToken[tokenID].isAllowed = _isAllowed;
    }

    
    function setTokenisAllowedList(uint tokenID,bool _isAllowedList) public  onlyOwner {
        tokenIdToToken[tokenID].isAllowedList = _isAllowedList;
    }

    
    function setTokenAllowedList(uint tokenID,address[] memory _allowedList,bool allow) public  onlyOwner {
        for (uint i = 0; i < _allowedList.length; i++) {
        allowedList[tokenID][_allowedList[i]] = allow;
        }
    }

    function setTokenAllowTransfer(uint tokenID,bool allow) public  onlyOwner {
       tokenIdToToken[tokenID].allowTransfer = allow;
    }
   

    
}