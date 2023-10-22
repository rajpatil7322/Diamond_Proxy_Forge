// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/******************************************************************************\
* Original Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Jesper Kristensen: modified to be simpler for demonstration purposes.
/******************************************************************************/

library LibDiamond {
    /// Storage slots of this diamond
    // load the storage of the diamond contract at a specific location:
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    event DiamondCut(FacetCut _diamondCut);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    struct FacetCut {
        address facetAddress; // address of the contract representing the facet of the diamond
        bytes4[] functionSelectors; // which functions from this new facet do we want registered
    }

    // Access existing facets and functions (aka selectors):
    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    /** ==================================================================
                        CUT NEW FACETS INTO THIS DIAMOND
    =====================================================================*/

    // The main function that is used to cut new facets into the diamond (aka add a new contract and its functions to the diamond)
    // Internal function version of diamondCut
    function diamondCut(FacetCut calldata _diamondCut)
    internal
    {
        address facetAddress = _diamondCut.facetAddress;
        bytes4[] memory functionSelectors = _diamondCut.functionSelectors;

        require(functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        require(facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");

        DiamondStorage storage ds = diamondStorage(); // store in "core" storage

        // where are we at in the selector array under this facet?
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[facetAddress].functionSelectors.length);

        // add new facet address if it does not exist
        if (selectorPosition == 0) { // no selectors have been registered under this facet ever: hence, the facet does not exist; add it:
            _enforceHasContractCode(facetAddress, "LibDiamondCut: New facet has no code");
            // store facet address
            ds.facetFunctionSelectors[facetAddress].facetAddressPosition = ds.facetAddresses.length;
            ds.facetAddresses.push(facetAddress);
        }

        // add each new incoming function selector to this facet
        for (uint256 selectorIndex; selectorIndex < functionSelectors.length; selectorIndex++) {
            bytes4 selector = functionSelectors[selectorIndex];
            
            // ensure the facet does not already exist:
            address currentFacetAddressIfAny = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(currentFacetAddressIfAny == address(0), "LibDiamondCut: Can't add function that already exists");

            // ADD The function (selector) here:
            // map the selector to the position in the overall selector array and also map it to the facet address
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            ds.selectorToFacetAndPosition[selector].facetAddress = facetAddress;
            // we track the selectors in an array under the facet address
            ds.facetFunctionSelectors[facetAddress].functionSelectors.push(selector);

            selectorPosition++;
        }
        emit DiamondCut(_diamondCut);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // uint16 selectorCount = uint16(diamondStorage().selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            _enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(oldFacetAddress, selector);
        }
    }
    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint16(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = uint16(facetAddressPosition);
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }



    /** ==================================================================
                            Core Diamond State
    =====================================================================*/

    // core diamond contract ownership:
    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address) {
        return diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(_msgSender() == contractOwner(), "LibDiamond: Must be contract owner");
    }

    // private functions in this section

    function _enforceHasContractCode(address _contract, string memory _errorMessage) private view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }

    function _msgSender() private view returns (address) {
        // put msg.sender behind a private view wall
        return msg.sender;
    }

    /** ==================================================================
                            General Diamond Storage Space
    =====================================================================*/

    /**
     * @notice Core diamond storage space (note that nft and erc20 are in different spaces)
     */
    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // owner of the diamond contract
        address contractOwner;
    }
    
    // access core storage via:
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}