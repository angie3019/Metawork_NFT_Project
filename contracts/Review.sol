//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
contract ReviewProject is ERC721, Ownable {
    
    
    string public name;
    string public symbol;
    
    using Counters for Counters.Counter;  // using counter for auto-incrementing the token id's
   Counters.Counter private reviewId;
    enum Reaction {dislike,like,love}
    
    struct Review {
        uint id;
        string title;
        string comment;
        Reaction reaction;
     }

    struct ProjectReviews{
        Review[] reviewArray;
    }
    
    
    mapping(address=>Review) userReviews;
    mapping (uint256 => string) private _tokenUris;

    constructor(string memory _name, string memory _symbol) ERC721('','') {
        name = _name;
        symbol = _symbol;
        
        
    }
    
    modifier checkReview(address user){
     require(userReviews[user].id==0,"Review already exists");
    _;
    }

    function createReview(string memory title,string memory comment,Reaction reaction) public checkReview(msg.sender){
        reviewId.increment();
        Review memory  review = Review(reviewId.current(),title,comment,reaction);
        userReviews[msg.sender] = review;
    }

    function mintReviewNFT(address to,uint id,string memory _uri) public onlyOwner  {       
        setTokenUri(_uri, id);
        _mint(to, id);
        
    }

    //Get reviews by user for a given project
    function getReviewsForUser(address reviewer)public view returns(Review memory){
        return userReviews[reviewer];
    }
    
    
    
    function updateReview(address reviewer,uint reviewID,string memory title,string memory comment,Reaction reaction)public {
        _burn(reviewID);
        reviewId.increment();
        Review memory  review = Review(reviewId.current(),title,comment,reaction);
        userReviews[reviewer]=review;
        
    }
   
    function tokenURI(uint256 id) override public view returns (string memory) {
        return(_tokenUris[id]);
    }
    

    function setTokenUri(string memory _uri,uint256 id) public onlyOwner {
        _tokenUris[id] = _uri; 
    }
 
    function safeTransferFrom(address from,address to,uint256 id) public pure  override {
        require(false,"Transfer not allowed");
        safeTransferFrom(from, to, id);
    }
    

}