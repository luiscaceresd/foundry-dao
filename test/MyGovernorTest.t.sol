// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { MyGovernor } from "../src/MyGovernor.sol";
import { Box } from "../src/Box.sol";
import { TimeLock } from "../src/TimeLock.sol";
import { GovToken } from "../src/GovToken.sol";

contract MyGovernorTest is Test {
  MyGovernor governor;
  Box box;
  TimeLock timelock;
  GovToken govToken;

  address public USER = makeAddr("user");
  uint256 public constant INITIAL_SUPPLY = 100 ether;

  uint256 public constant MIN_DELAY = 3600; // 1h - after vote passed
  
  address[] proposers;
  address[] executors;
  uint256[] values;
  bytes[] calldatas;
  address[] targets;
  
  function setUp() public {
    govToken = new GovToken(USER);
    govToken.mint(USER, INITIAL_SUPPLY);

    vm.startPrank(USER);
    govToken.delegate(USER);
    timelock = new TimeLock(MIN_DELAY, proposers, executors);
    governor = new MyGovernor(govToken, timelock);  
    
    bytes32 proposerRole = timelock.PROPOSER_ROLE();
    bytes32 executorRole = timelock.EXECUTOR_ROLE();
    bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();

    timelock.grantRole(proposerRole, address(governor));
    timelock.grantRole(executorRole, address(0));
    timelock.revokeRole(adminRole, USER);
    vm.stopPrank();

    box = new Box();
    box.transferOwnership(address(timelock));
  }

  function testCantUpdateBoxWithoutGovernance() public {
    vm.expectRevert();
    box.store(1);
  }

  function testGovernanceUpdatesBox() public {
    uint256 valueToStore = 888;
    string memory description = "Store 1 in box";
    bytes memory encodedFunctionCall = abi.encodeWithSignature("store(uint256)", valueToStore);
    
    values.push(0);
    calldatas.push(encodedFunctionCall);
    targets.push(address(box));

    // 1. Propose to the DAO
    uint256 proposalId = governor.propose(targets, values, calldatas, description);
  }
} 