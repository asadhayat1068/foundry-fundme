// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant STARTING_VALUE = 10 ether;
    uint256 private fundValue = 10000000000000000;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_VALUE);
    }

    function testMinimumDollarIsFive() public view {
        assertEqUint(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerisMessageSender() external view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testFundMeVersionIsAccurate() external view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEths() public {
        vm.expectRevert();
        fundMe.fund();
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: fundValue}();
        _;
    }

    function testFundUpdatesFundingDataStructures() public funded {
        assertEq(fundMe.getAddressToAmountFunded(USER), fundValue);
    }

    function testAddFunderToArrayOfFunders() public funded {
        uint256 funderIndex = 0;
        address receiverFunder = fundMe.getFunder(funderIndex);
        assertEq(receiverFunder, USER);
    }

    function testNonOwnerCannotWithdraw() public funded {
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testOnlyOwnerCanWithdraw() public funded {
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawWithMultipleFunders() public funded {
        uint160 numberOfSenders = 10;
        uint160 startingIndex = 1;
        for (uint160 i = startingIndex; i < numberOfSenders; i++) {
            hoax(address(i), fundValue);
            fundMe.fund{value: fundValue}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            endingOwnerBalance
        );
    }
}
