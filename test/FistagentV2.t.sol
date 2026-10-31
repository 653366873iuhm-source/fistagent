// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {FistagentMint} from "../src/FistagentMint.sol";
import {FistagentToken} from "../src/FistagentToken.sol";
import {IV2Pair, IAgentIdRegistry} from "../src/interfaces/IExternal.sol";
import {BscConfig} from "../script/BscConfig.sol";

interface IPairBal {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256, uint256, address[] calldata, address, uint256
    ) external;
}

/// @notice FISTAGENT v2 rules on a BSC mainnet fork (BSC_RPC_URL, optional FORK_BLOCK).
contract FistagentV2Test is Test {
    FistagentMint mint;
    FistagentToken token;
    IV2Pair pair;
    IERC20 usdt = IERC20(BscConfig.USDT);
    IAgentIdRegistry reg = IAgentIdRegistry(BscConfig.AGENT_ID_REGISTRY);
    address treasury = BscConfig.TREASURY;
    address deployer = BscConfig.DEPLOYER;
    address constant ALICE = 0x5d2A279e91A4e82bB327f5c98Fb48C72F7Cb39e3; // htetwai.ai
    address constant BOB = 0xd72106AAd68223AfA37CcB7f8a8A14f2F2a353C3; // chmon.ai
    address constant NOBODY = address(0xBEEF0001);
    address bulk = address(0xB01C);
    uint256 nonce;
    uint256 startTs;

    function setUp() public {
        uint256 blk = vm.envOr("FORK_BLOCK", uint256(0));
        if (blk == 0) vm.createSelectFork(vm.envString("BSC_RPC_URL"));
        else vm.createSelectFork(vm.envString("BSC_RPC_URL"), blk);
        vm.prank(deployer);
        mint = new FistagentMint(BscConfig.params(BscConfig.SOCIAL_SIGNER));
        token = mint.token();
        pair = mint.pair();
        assertEq(mint.operator(), deployer);
        assertEq(mint.treasury(), treasury);
        assertTrue(mint.paused());
        vm.prank(deployer);
        mint.setPaused(false);
        startTs = block.timestamp;
        deal(BscConfig.USDT, bulk, 20_000 ether);
        vm.prank(bulk);
        usdt.approve(address(mint), type(uint256).max);
        deal(BscConfig.USDT, ALICE, 100 ether);
        vm.prank(ALICE);
        usdt.approve(address(mint), type(uint256).max);
    }

    function _id() internal {
        string memory h = string.concat("bulk", vm.toString(++nonce));
        uint256 id = uint256(keccak256(bytes(h)));
        vm.mockCall(address(reg), abi.encodeCall(IAgentIdRegistry.handleOf, (bulk)), abi.encode(h));
        vm.mockCall(address(reg), abi.encodeCall(IAgentIdRegistry.ownerOf, (id)), abi.encode(bulk));
    }

    function _free(uint256 n) internal {
        for (uint256 i; i < n; i++) {
            _id();
            vm.prank(bulk);
            mint.claimFree();
        }
    }

    function _paid(uint256 n) internal {
        while (n > 0) {
            uint256 k = n > 10 ? 10 : n;
            _id();
            vm.prank(bulk);
            mint.mint(k, address(0), type(uint256).max);
            n -= k;
        }
    }

    function test_FreeClaimRules() public {
        assertEq(mint.BURNED_SHARES(), 0);
        assertEq(mint.totalMinted(), 0);
        vm.prank(ALICE);
        mint.claimFree();
        assertEq(token.balanceOf(ALICE), 50_000_000 ether, "free share = 50M tokens");
        assertEq(mint.totalMinted(), 1);
        assertEq(mint.pendingTokens(), 40_000_000 ether);
        assertEq(mint.pendingUsdt(), 0);
        assertEq(usdt.balanceOf(ALICE), 100 ether, "nothing paid");
        vm.prank(ALICE);
        vm.expectRevert(FistagentMint.FreeUsed.selector);
        mint.claimFree();
        vm.prank(NOBODY);
        vm.expectRevert(FistagentMint.NoAgent.selector);
        mint.claimFree();
        vm.prank(ALICE);
        vm.expectRevert(FistagentMint.FreePhase.selector);
        mint.mint(1, address(0), 1 ether);
        (,, uint256 minted,,) = mint.walletStatus(ALICE);
        assertEq(minted, 0, "free share does not use paid quota");
    }

    function test_PausedBlocksFree() public {
        vm.prank(deployer);
        mint.setPaused(true);
        vm.prank(ALICE);
        vm.expectRevert(FistagentMint.Paused.selector);
        mint.claimFree();
    }

    function test_PaidPhaseAllParkedThenOpen() public {
        _free(2_000);
        vm.prank(BOB);
        vm.expectRevert(FistagentMint.FreeOver.selector);
        mint.claimFree();
        assertEq(mint.costOf(1), 1 ether);
        uint256 t0 = usdt.balanceOf(treasury);
        vm.prank(ALICE);
        mint.mint(10, address(0), 10 ether);
        assertEq(token.balanceOf(ALICE), 500_000_000 ether);
        assertEq(usdt.balanceOf(treasury), t0, "nothing to treasury before open");
        assertEq(mint.pendingUsdt(), 10 ether, "100% parked");
        vm.prank(ALICE);
        vm.expectRevert(FistagentMint.Quota.selector);
        mint.mint(1, address(0), 1 ether);
        _paid(7_985);
        assertEq(mint.totalMinted(), 9_995);
        assertEq(mint.pendingUsdt(), 7_995 ether);
        assertEq(usdt.balanceOf(address(mint)), 7_995 ether);
        assertEq(mint.pendingTokens(), 9_995 * 40_000_000 ether);
        assertFalse(mint.opened());
        _id();
        vm.prank(bulk);
        mint.mint(10, address(0), type(uint256).max);
        assertTrue(mint.opened());
        assertTrue(token.tradingEnabled());
        (uint256 u, uint256 t) = mint.reserves();
        assertEq(u, 8_000 ether, "pool opens with 8,000 USDT");
        assertLe(t, 400_000_000_000 ether);
        assertGe(t, 396_825_000_000 ether, "only the <=0.8%/tx floor burn");
        assertEq(usdt.balanceOf(treasury) - t0, 5 * 1.1 ether, "post-open shares: 100% to treasury");
        assertEq(usdt.balanceOf(address(mint)), 0);
        uint256 lp = IPairBal(address(pair)).totalSupply();
        assertEq(IPairBal(address(pair)).balanceOf(mint.DEAD()) + 1_000, lp, "all LP at dead");
        assertEq(IPairBal(address(pair)).balanceOf(treasury) + IPairBal(address(pair)).balanceOf(deployer), 0);

        // taxes still go to the treasury in BNB
        address trader = address(0x7EADE5);
        deal(BscConfig.USDT, trader, 50 ether);
        address[] memory path = new address[](2);
        path[0] = BscConfig.USDT;
        path[1] = address(token);
        vm.startPrank(trader);
        usdt.approve(BscConfig.PANCAKE_V2_ROUTER, 50 ether);
        IRouter(BscConfig.PANCAKE_V2_ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            50 ether, 0, path, trader, block.timestamp
        );
        vm.stopPrank();
        assertGt(token.balanceOf(address(mint)), 0, "buy tax held");
        vm.roll(block.number + 1);
        uint256 b0 = treasury.balance;
        mint.swapTax();
        assertGt(treasury.balance, b0, "tax BNB to treasury");
    }

    function test_ValveOnlyTreasury() public {
        _free(2_000);
        vm.prank(ALICE);
        mint.mint(10, address(0), 10 ether);
        vm.prank(treasury);
        vm.expectRevert(FistagentMint.DeadlineNotReached.selector);
        mint.withdrawUnfilled();
        vm.warp(startTs + 30 days + 1);
        vm.prank(deployer);
        vm.expectRevert(FistagentMint.NotTreasury.selector);
        mint.withdrawUnfilled();
        vm.prank(ALICE);
        vm.expectRevert(FistagentMint.NotTreasury.selector);
        mint.withdrawUnfilled();
        uint256 t0 = usdt.balanceOf(treasury);
        vm.prank(treasury);
        mint.withdrawUnfilled();
        assertEq(usdt.balanceOf(treasury) - t0, 10 ether, "all parked USDT to treasury");
        assertEq(token.balanceOf(mint.DEAD()), 2_010 * 40_000_000 ether, "parked tokens to dead");
    }

    function test_OperatorOnlyPause() public {
        vm.startPrank(deployer);
        vm.expectRevert(FistagentMint.NotTreasury.selector);
        mint.renounce();
        vm.expectRevert(FistagentMint.NotTreasury.selector);
        mint.setPoolBlocked(address(0x1234), true);
        vm.stopPrank();
        vm.prank(treasury);
        mint.setPaused(true);
        vm.prank(treasury);
        mint.renounce();
        vm.prank(deployer);
        vm.expectRevert(FistagentMint.AdminRenounced.selector);
        mint.setPaused(true);
        assertFalse(mint.paused());
    }
}
