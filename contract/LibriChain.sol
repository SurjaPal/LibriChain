// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title LibriChain — simple on-chain book lending/borrowing record system
/// @author
/// @notice Beginner example: preloaded books; borrow the next available book with no input fields
contract LibriChain {
    struct Book {
        uint256 id;
        string title;
        string author;
        address borrower;       // address who borrowed (address(0) if available)
        uint256 borrowTimestamp;
    }

    Book[] private books;
    mapping(address => uint256[]) private borrowedBy; // who borrowed which book IDs
    address public owner;

    event BookBorrowed(uint256 indexed bookId, address indexed borrower, uint256 timestamp);
    event BookReturned(uint256 indexed bookId, address indexed borrower, uint256 timestamp);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    constructor() {
        owner = msg.sender;

        // Preload a few books so the contract can be used without input fields
        books.push(Book({ id: 0, title: "Pride and Prejudice", author: "Jane Austen", borrower: address(0), borrowTimestamp: 0 }));
        books.push(Book({ id: 1, title: "Moby-Dick", author: "Herman Melville", borrower: address(0), borrowTimestamp: 0 }));
        books.push(Book({ id: 2, title: "The Odyssey", author: "Homer", borrower: address(0), borrowTimestamp: 0 }));
    }

    /// @notice Borrow the first available book (no input fields)
    /// @dev Finds the first book with borrower == address(0) and assigns it to msg.sender
    /// @return bookId the id of the book borrowed
    function borrowAny() external returns (uint256 bookId) {
        for (uint256 i = 0; i < books.length; i++) {
            if (books[i].borrower == address(0)) {
                books[i].borrower = msg.sender;
                books[i].borrowTimestamp = block.timestamp;
                borrowedBy[msg.sender].push(books[i].id);
                emit BookBorrowed(books[i].id, msg.sender, block.timestamp);
                return books[i].id;
            }
        }
        revert("no available books");
    }

    /// @notice Return all books borrowed by the caller (no input fields)
    /// @dev Marks all the caller's borrowed books as available again and clears their list
    function returnAll() external {
        uint256[] storage list = borrowedBy[msg.sender];
        require(list.length > 0, "no borrowed books");

        for (uint256 i = 0; i < list.length; i++) {
            uint256 id = list[i];
            // defensive check — book id should be valid
            if (id < books.length && books[id].borrower == msg.sender) {
                books[id].borrower = address(0);
                books[id].borrowTimestamp = 0;
                emit BookReturned(id, msg.sender, block.timestamp);
            }
        }

        // clear the caller's borrowed list
        delete borrowedBy[msg.sender];
    }

    /// @notice Get the list of book IDs currently borrowed by the caller
    /// @dev view function, no inputs required
    function getMyBorrowedIds() external view returns (uint256[] memory) {
        return borrowedBy[msg.sender];
    }

    /// @notice Get basic info for all books (id, title, author, available)
    /// @dev This returns arrays of primitive types for easy consumption off-chain
    function getAllBooks()
        external
        view
        returns (
            uint256[] memory ids,
            string[] memory titles,
            string[] memory authors,
            address[] memory borrowers,
            uint256[] memory borrowTimestamps
        )
    {
        uint256 n = books.length;
        ids = new uint256[](n);
        titles = new string[](n);
        authors = new string[](n);
        borrowers = new address[](n);
        borrowTimestamps = new uint256[](n);

        for (uint256 i = 0; i < n; i++) {
            Book storage b = books[i];
            ids[i] = b.id;
            titles[i] = b.title;
            authors[i] = b.author;
            borrowers[i] = b.borrower;
            borrowTimestamps[i] = b.borrowTimestamp;
        }
    }

    /// ------ Owner utilities (optional) ------

    /// @notice Change contract owner
    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero address");
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }

    /// @notice Owner can preload an extra book without user input forms by supplying literals in code when calling
    /// @dev This function takes inputs — keep it owner-only so normal users don't need to supply inputs
    function ownerAddBook(string calldata title, string calldata author) external onlyOwner {
        uint256 id = books.length;
        books.push(Book({ id: id, title: title, author: author, borrower: address(0), borrowTimestamp: 0 }));
    }
}

