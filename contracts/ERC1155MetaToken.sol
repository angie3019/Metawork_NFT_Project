//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ERC1155MetaToken is ERC1155, Ownable {
    string public name;
    string public symbol;
    string public baseURI;
    string public baseExtension = ".json";
    bool allowsTransfers = false;
    mapping(uint256 =>mapping(address => bool)) allowedList;
    mapping(uint256 => Token) public tokenIdToToken;
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
     }

    constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC1155('') {
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
        
    }

    modifier checkMinting() {
        if (tokenIdToToken[tokenId.current()].limited) {
            require (
                tokenIdToToken[tokenId.current()].tokenMinted < tokenIdToToken[tokenId.current()].tokenLimit,
                "Max tokens issued"
            );
        }
        _;
    }


    // Creating Cohort for buildspace
    function createToken(string memory _name, bool _limited, uint128 _limit,bool _allowed, bool _allowedList) external  onlyOwner {
       /*  require(
            tokenIdToToken[tokenId.current()].tokenLimit == 0,
            "Token already exists"
        ); */
        // ID, Name, Limited, Limit, Minted,external minting allowed,minting allowed by list
       
       tokenId.increment();
       Token memory token = Token(tokenId.current(), _name, _limited, _limit, 0,_allowed, _allowedList);
       tokenIdToToken[tokenId.current()] = token;
    }

    // set token isAllowed - owner
    function setTokenisAllowed(bool _isallowed) public  onlyOwner {
        tokenIdToToken[tokenId.current()].isAllowed = _isallowed;
    }

    // Set token isallowedlist - owner
    function setTokenisAllowedList(bool _isallowedList) public  onlyOwner {
        tokenIdToToken[tokenId.current()].isAllowedList = _isallowedList;
    }

    // Set allowedList of addresses for token
    function setTokenAllowedList(address[] memory _allowedList) public  onlyOwner {
        for (uint i = 0; i < _allowedList.length; i++) {
        allowedList[tokenId.current()][_allowedList[i]] = true;
        }
    }
    

    function mintTokenItem(address to) public onlyOwner checkMinting {       
        _mint(to, tokenId.current(), 1, '');
        tokenIdToToken[tokenId.current()].tokenMinted += 1;
  
    }

    function mintTokenItemOther(address to) public checkMinting {
        
       // Either the sender can be owner or belong to an allowed address for this token 
        require((tokenIdToToken[tokenId.current()].isAllowed) || ( tokenIdToToken[tokenId.current()].isAllowedList && allowedList[tokenId.current()][msg.sender]) ,"User is not allowed to mint this token");
        _mint(to, tokenId.current(), 1, '');
        tokenIdToToken[tokenId.current()].tokenMinted += 1;
       
        if(tokenIdToToken[tokenId.current()].isAllowedList)
            allowedList[tokenId.current()][msg.sender] = false;
     }


    function batchMintTokenItem(address[] memory to) public onlyOwner checkMinting {
   
        for (uint i = 0; i < to.length; i++) {
            mintTokenItem(to[i]);
        }
    }
    function batchMintTokenItemOther(address[] memory to) public  checkMinting {
   
        for (uint i = 0; i < to.length; i++) {
            mintTokenItemOther(to[i]);
        }
    }

    function uri(uint256 tokenID) override public view returns (string memory) {
        return (
            string(abi.encodePacked(
                baseURI,
                Strings.toString(tokenID),
                baseExtension
                ))
            );
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
   
/*
    function getAllowedList(uint256 _tokenId) public view returns (mapping(address=>bool) memory) {
        return allowedList[_tokenId];
    }*/
}