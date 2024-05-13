// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "openzeppelin/token/ERC20/IERC20.sol";
import "joe-v2/libraries/Constants.sol";
import "joe-v2/libraries/math/LiquidityConfigurations.sol";
import "joe-v2/interfaces/ILBFactory.sol";

import "../src/periphery/LiquidityHelper.sol";
import "../src/LiquidityHelperContract.sol";

contract TestHelper is Test {
    address immutable alice = makeAddr("alice");
    address immutable bob = makeAddr("bob");

    LiquidityHelperContract helper;

    ILBFactory lbFactory = ILBFactory(0x8e42f2F4101563bF679975178e880FD87d3eFd4e);

    ILBPair lbPair0;
    ILBPair lbPair1;

    function setUp() public {
        vm.createSelectFork(StdChains.getChain("avalanche").rpcUrl, 29458842);

        helper = new LiquidityHelperContract();

        lbPair0 = lbFactory.getLBPairAtIndex(0);
        lbPair1 = lbFactory.getLBPairAtIndex(1);
    }

    function addLiquidity(address to, ILBPair lbPair, uint256 amountX, uint256 amountY, uint8 nbBinX, uint8 nbBinY)
        public
        returns (uint256[] memory ids, uint256[] memory shares)
    {
        IERC20 tokenX = lbPair.getTokenX();
        IERC20 tokenY = lbPair.getTokenY();

        deal(address(tokenX), address(this), amountX);
        deal(address(tokenY), address(this), amountY);

        uint256 total = getTotalBins(nbBinX, nbBinY);
        uint24 activeId = lbPair.getActiveId();

        ids = new uint256[](total);
        bytes32[] memory liquidityConfigurations = new bytes32[](total);

        for (uint256 i; i < total; ++i) {
            uint24 id = getId(activeId, i, nbBinY);

            uint64 distribX = id >= activeId && nbBinX > 0 ? uint64(Constants.PRECISION / nbBinX) : 0;
            uint64 distribY = id <= activeId && nbBinY > 0 ? uint64(Constants.PRECISION / nbBinY) : 0;

            ids[i] = uint256(id);
            liquidityConfigurations[i] = LiquidityConfigurations.encodeParams(distribX, distribY, id);
        }

        IERC20(tokenX).transfer(address(lbPair), amountX);
        IERC20(tokenY).transfer(address(lbPair), amountY);

        (,, shares) = lbPair.mint(to, liquidityConfigurations, address(this));
    }

    function burnLiquidity(address from, ILBPair lbPair, uint256[] memory ids, uint256[] memory shares)
        public
        returns (uint256 amountX, uint256 amountY)
    {
        IERC20 tokenX = lbPair.getTokenX();
        IERC20 tokenY = lbPair.getTokenY();

        (amountX, amountY) = (tokenX.balanceOf(from), tokenY.balanceOf(from));
        vm.prank(from);
        lbPair.burn(from, from, ids, shares);
        (amountX, amountY) = (tokenX.balanceOf(from) - amountX, tokenY.balanceOf(from) - amountY);
    }

    function swapNbBins(ILBPair lbPair, bool swapForY, uint24 nbBin) public {
        require(nbBin > 0, "TestHelper: nbBin must be > 0");

        uint24 id = lbPair.getActiveId();
        uint128 reserve;

        for (uint24 i = 0; i <= nbBin; i++) {
            uint24 nextId = swapForY ? id - i : id + i;
            (uint128 binReserveX, uint128 binReserveY) = lbPair.getBin(nextId);

            uint128 amount = swapForY ? binReserveY : binReserveX;

            if (i == nbBin) {
                amount /= 2;
            }

            reserve += amount;
        }

        (uint128 amountIn,,) = lbPair.getSwapIn(reserve, swapForY);

        IERC20 tokenX = lbPair.getTokenX();
        IERC20 tokenY = lbPair.getTokenY();

        deal(address(swapForY ? tokenX : tokenY), address(this), amountIn);

        (swapForY ? tokenX : tokenY).transfer(address(lbPair), amountIn);

        lbPair.swap(swapForY, address(1));

        require(lbPair.getActiveId() == (swapForY ? id - nbBin : id + nbBin), "TestHelper: invalid active bin");
    }

    function getTotalBins(uint8 nbBinX, uint8 nbBinY) public pure returns (uint256) {
        return nbBinX > 0 && nbBinY > 0 ? nbBinX + nbBinY - 1 : nbBinX + nbBinY;
    }

    function getId(uint24 activeId, uint256 i, uint8 nbBinY) public pure returns (uint24 id) {
        uint256 id_ = activeId + i;
        id_ = nbBinY > 0 ? id_ - nbBinY + 1 : id_;

        require((id = uint24(id_)) == id_, "id overflow");
    }
}
