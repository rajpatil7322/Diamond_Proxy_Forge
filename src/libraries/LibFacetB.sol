/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library LibFacetB {
    bytes32 constant STORAGE_POSITION = keccak256("facet.a.diamond.storage");

    struct Storage {
        uint256 b;
        string data;
    }

    function getStorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function sub(uint256 _num) internal returns(bool){
        Storage storage ds=getStorage();
        unchecked{
            ds.b-=_num;
        }
        return true;
    }

    function addData(string calldata _data) internal returns(bool){
        Storage storage ds=getStorage();
        ds.data=_data;
        return true;
    }
}