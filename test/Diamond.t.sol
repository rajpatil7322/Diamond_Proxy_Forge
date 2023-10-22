// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Diamond} from "../src/Diamond.sol";
import {FacetA} from "../src/facet/FacetA.sol";

contract DiamondTest is Test {
    Diamond public diamond;
    FacetA public facetA;

    address public addr1;
    address public addr2;
    address public addr3;
    address public addr4;

     struct FacetCut {
        address facetAddress; // address of the contract representing the facet of the diamond
        bytes4[] functionSelectors; // which functions from this new facet do we want registered
    }

    function setUp() public {
        addr1=vm.addr(1);
        vm.prank(addr1);
        diamond = new Diamond(addr1);
        facetA=new FacetA();
    }

    function test_deployment() public  view{
        console2.log(addr1);
        console2.log(diamond.getOwner());
    }

    function test_diamond_cut() public{
        bytes4 selc1=bytes4(keccak256(bytes("add(uint256)")));
        bytes4 selc2=bytes4(keccak256(bytes("getNum()")));
       

        FacetCut memory data;
        data.facetAddress=address(facetA);
        data.functionSelectors[0]=selc1;


        console2.log(data.functionSelectors.length);
        
    }   

}
