// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibFacetA} from "../libraries/LibFacetA.sol";


contract FacetA {

    function add(uint256 _num) external returns(bool){
        return LibFacetA.add(_num);
    }

    function getNum() public view returns(uint256){
        return LibFacetA.getStorage().a;
    }

    function multiply(uint256 _num) external returns(bool){
        return LibFacetA.multiply(_num);
    }
}