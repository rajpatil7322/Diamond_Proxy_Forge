/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library LibFacetA {
    bytes32 constant STORAGE_POSITION = keccak256("facet.a.diamond.storage");

    struct Storage {
        uint256 a;
    }

    function getStorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function add(uint256 _num) internal returns(bool){
        Storage storage ds=getStorage();
        ds.a+=_num;
        return true;
    }

    function multiply(uint256 _num) internal returns(bool){
        Storage storage ds=getStorage();
        ds.a*=_num;
        return true;
    }
}