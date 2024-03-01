// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TestHelper.sol";

contract TestLiquidityHelper is TestHelper {
    using Uint256x256Math for uint256;

    function test_GetSharesOf() public {
        (uint256[] memory aliceIds, uint256[] memory aliceShares) = addLiquidity(alice, lbPair0, 1e18, 20e6, 4, 4);

        uint256[] memory sharesOfAlice = helper.getSharesOf(lbPair0, alice, aliceIds);

        assertEq(sharesOfAlice.length, aliceShares.length, "test_GetSharesOf::1");

        for (uint256 i; i < aliceShares.length; ++i) {
            assertEq(sharesOfAlice[i], aliceShares[i], "test_GetSharesOf::2");
        }

        (uint256[] memory bobIds, uint256[] memory bobShares) = addLiquidity(bob, lbPair1, 2e18, 40e6, 1, 1);

        uint256[] memory sharesOfBob = helper.getSharesOf(lbPair1, bob, bobIds);

        assertEq(sharesOfBob.length, bobShares.length, "test_GetSharesOf::3");

        for (uint256 i; i < bobShares.length; ++i) {
            assertEq(sharesOfBob[i], bobShares[i], "test_GetSharesOf::4");
        }

        sharesOfAlice = helper.getSharesOf(lbPair1, alice, bobIds);

        for (uint256 i; i < sharesOfAlice.length; ++i) {
            assertEq(sharesOfAlice[i], 0, "test_GetSharesOf::5");
        }

        sharesOfBob = helper.getSharesOf(lbPair0, bob, aliceIds);

        for (uint256 i; i < sharesOfBob.length; ++i) {
            assertEq(sharesOfBob[i], 0, "test_GetSharesOf::6");
        }
    }

    function test_GetLiquiditiesOf() public {
        (uint256[] memory aliceIds, uint256[] memory aliceShares) = addLiquidity(alice, lbPair0, 1e18, 20e6, 4, 4);

        uint256[] memory aliceLiquidities = helper.getLiquiditiesOf(lbPair0, alice, aliceIds);

        assertEq(aliceLiquidities.length, aliceShares.length, "test_GetLiquiditiesOf::1");

        uint16 binStep = lbPair0.getBinStep();

        for (uint256 i; i < aliceShares.length; ++i) {
            uint24 id = uint24(aliceIds[i]);
            uint256 price = PriceHelper.getPriceFromId(id, binStep);
            (uint256 binX, uint256 binY) = lbPair0.getBin(id);
            uint256 totalShares = lbPair0.totalSupply(id);

            uint256 amountX = aliceShares[i].mulDivRoundDown(binX, totalShares);
            uint256 amountY = aliceShares[i].mulDivRoundDown(binY, totalShares);

            uint256 liquidity = price.mulShiftRoundDown(amountX, Constants.SCALE_OFFSET) + amountY;

            assertEq(liquidity, aliceLiquidities[i], "test_GetLiquiditiesOf::2");
        }

        (uint256[] memory bobIds, uint256[] memory bobShares) = addLiquidity(bob, lbPair1, 2e18, 40e6, 1, 1);

        uint256[] memory bobLiquidities = helper.getLiquiditiesOf(lbPair1, bob, bobIds);

        assertEq(bobLiquidities.length, bobShares.length, "test_GetLiquiditiesOf::3");

        binStep = lbPair1.getBinStep();

        for (uint256 i; i < bobShares.length; ++i) {
            uint24 id = uint24(bobIds[i]);
            uint256 price = PriceHelper.getPriceFromId(id, binStep);
            (uint256 binX, uint256 binY) = lbPair1.getBin(id);
            uint256 totalShares = lbPair1.totalSupply(id);

            uint256 amountX = bobShares[i].mulDivRoundDown(binX, totalShares);
            uint256 amountY = bobShares[i].mulDivRoundDown(binY, totalShares);

            uint256 liquidity = price.mulShiftRoundDown(amountX, Constants.SCALE_OFFSET) + amountY;

            assertEq(liquidity, bobLiquidities[i], "test_GetLiquiditiesOf::4");
        }

        aliceLiquidities = helper.getLiquiditiesOf(lbPair1, alice, bobIds);

        for (uint256 i; i < aliceLiquidities.length; ++i) {
            assertEq(aliceLiquidities[i], 0, "test_GetLiquiditiesOf::5");
        }

        bobLiquidities = helper.getLiquiditiesOf(lbPair0, bob, aliceIds);

        for (uint256 i; i < bobLiquidities.length; ++i) {
            assertEq(bobLiquidities[i], 0, "test_GetLiquiditiesOf::6");
        }
    }

    function test_GetAmountsOf() public {
        (uint256[] memory aliceIds, uint256[] memory aliceShares) = addLiquidity(alice, lbPair0, 1e18, 20e6, 4, 4);

        (uint256[] memory aliceAmountsX, uint256[] memory aliceAmountsY) = helper.getAmountsOf(lbPair0, alice, aliceIds);

        assertEq(aliceAmountsX.length, aliceShares.length, "getAmountsOf::1");
        assertEq(aliceAmountsY.length, aliceShares.length, "getAmountsOf::2");

        for (uint256 i; i < aliceShares.length; ++i) {
            uint24 id = uint24(aliceIds[i]);
            (uint256 binX, uint256 binY) = lbPair0.getBin(id);
            uint256 totalShares = lbPair0.totalSupply(id);

            uint256 amountX = aliceShares[i].mulDivRoundDown(binX, totalShares);
            uint256 amountY = aliceShares[i].mulDivRoundDown(binY, totalShares);

            assertEq(amountX, aliceAmountsX[i], "getAmountsOf::3");
            assertEq(amountY, aliceAmountsY[i], "getAmountsOf::4");
        }

        (uint256[] memory bobIds, uint256[] memory bobShares) = addLiquidity(bob, lbPair1, 2e18, 40e6, 1, 1);

        (uint256[] memory bobAmountsX, uint256[] memory bobAmountsY) = helper.getAmountsOf(lbPair1, bob, bobIds);

        assertEq(bobAmountsX.length, bobShares.length, "getAmountsOf::5");
        assertEq(bobAmountsY.length, bobShares.length, "getAmountsOf::6");

        for (uint256 i; i < bobShares.length; ++i) {
            uint24 id = uint24(bobIds[i]);
            (uint256 binX, uint256 binY) = lbPair1.getBin(id);
            uint256 totalShares = lbPair1.totalSupply(id);

            uint256 amountX = bobShares[i].mulDivRoundDown(binX, totalShares);
            uint256 amountY = bobShares[i].mulDivRoundDown(binY, totalShares);

            assertEq(amountX, bobAmountsX[i], "getAmountsOf::7");
            assertEq(amountY, bobAmountsY[i], "getAmountsOf::8");
        }

        (aliceAmountsX, aliceAmountsY) = helper.getAmountsOf(lbPair1, alice, bobIds);

        for (uint256 i; i < aliceAmountsX.length; ++i) {
            assertEq(aliceAmountsX[i], 0, "getAmountsOf::9");
            assertEq(aliceAmountsY[i], 0, "getAmountsOf::10");
        }

        (bobAmountsX, bobAmountsY) = helper.getAmountsOf(lbPair0, bob, aliceIds);

        for (uint256 i; i < bobAmountsX.length; ++i) {
            assertEq(bobAmountsX[i], 0, "getAmountsOf::11");
            assertEq(bobAmountsY[i], 0, "getAmountsOf::12");
        }
    }

    function test_GetSharesForAmountsAndAmountsForShares() public {
        uint24 activeId = lbPair0.getActiveId();

        uint256[] memory ids = new uint256[](11);
        uint256[] memory shares = new uint256[](11);

        for (uint256 i; i < ids.length; ++i) {
            ids[i] = activeId - 5 + i;
            shares[i] = lbPair0.totalSupply(uint24(ids[i])) / (1 + i);
        }

        (uint256[] memory amountsX, uint256[] memory amountsY) = helper.getAmountsForShares(lbPair0, ids, shares);

        uint256[] memory sharesForAmounts = helper.getSharesForAmounts(lbPair0, ids, amountsX, amountsY);

        assertEq(sharesForAmounts.length, shares.length, "test_GetSharesForAmountsAndAmountsForShares::1");

        for (uint256 i; i < sharesForAmounts.length; ++i) {
            assertApproxEqRel(sharesForAmounts[i], shares[i], 1e10, "test_GetSharesForAmountsAndAmountsForShares::2");
        }

        (uint256[] memory amountsX1, uint256[] memory amountsY1) =
            helper.getAmountsForShares(lbPair0, ids, sharesForAmounts);

        assertEq(amountsX1.length, amountsX.length, "test_GetSharesForAmountsAndAmountsForShares::3");

        for (uint256 i; i < amountsX1.length; ++i) {
            assertApproxEqRel(amountsX1[i], amountsX[i], 1e10, "test_GetSharesForAmountsAndAmountsForShares::4");
            assertApproxEqRel(amountsY1[i], amountsY[i], 1e10, "test_GetSharesForAmountsAndAmountsForShares::5");
        }
    }

    function test_GetLiquiditiesForAmountsAndAmountsForLiquidities() public {
        uint24 activeId = lbPair0.getActiveId();

        uint256[] memory ids = new uint256[](11);
        uint256[] memory amountsX = new uint256[](11);
        uint256[] memory amountsY = new uint256[](11);

        for (uint256 i; i < ids.length; ++i) {
            ids[i] = activeId - 5 + i;

            (uint256 binX, uint256 binY) = lbPair0.getBin(uint24(ids[i]));

            amountsX[i] = binX / (1 + i);
            amountsY[i] = binY / (1 + i);
        }

        uint256[] memory liquidities = helper.getLiquiditiesForAmounts(lbPair0, ids, amountsX, amountsY);

        (uint256[] memory amountsX1, uint256[] memory amountsY1) =
            helper.getAmountsForLiquidities(lbPair0, ids, liquidities);

        assertEq(amountsX1.length, amountsX.length, "test_GetLiquiditiesForAmountsAndAmountsForLiquidities::1");

        for (uint256 i; i < amountsX1.length; ++i) {
            assertApproxEqRel(
                amountsX1[i], amountsX[i], 1e10, "test_GetLiquiditiesForAmountsAndAmountsForLiquidities::2"
            );
            assertApproxEqRel(
                amountsY1[i], amountsY[i], 1e10, "test_GetLiquiditiesForAmountsAndAmountsForLiquidities::3"
            );
        }

        uint256[] memory liquidities1 = helper.getLiquiditiesForAmounts(lbPair0, ids, amountsX1, amountsY1);

        assertEq(liquidities1.length, liquidities.length, "test_GetLiquiditiesForAmountsAndAmountsForLiquidities::4");

        for (uint256 i; i < liquidities1.length; ++i) {
            assertApproxEqRel(
                liquidities1[i], liquidities[i], 1e10, "test_GetLiquiditiesForAmountsAndAmountsForLiquidities::5"
            );
        }
    }

    function test_GetLiquiditiesForSharesAndSharesForLiquidities() public {
        uint24 activeId = lbPair0.getActiveId();

        uint256[] memory ids = new uint256[](11);
        uint256[] memory shares = new uint256[](11);

        for (uint256 i; i < ids.length; ++i) {
            ids[i] = activeId - 5 + i;
            shares[i] = lbPair0.totalSupply(uint24(ids[i])) / (1 + i);
        }

        uint256[] memory liquidities = helper.getLiquiditiesForShares(lbPair0, ids, shares);

        uint256[] memory sharesForLiquidities = helper.getSharesForLiquidities(lbPair0, ids, liquidities);

        assertEq(sharesForLiquidities.length, shares.length, "test_GetLiquiditiesForSharesAndSharesForLiquidities::1");

        for (uint256 i; i < sharesForLiquidities.length; ++i) {
            assertApproxEqRel(
                sharesForLiquidities[i], shares[i], 1e10, "test_GetLiquiditiesForSharesAndSharesForLiquidities::2"
            );
        }

        uint256[] memory liquidities1 = helper.getLiquiditiesForShares(lbPair0, ids, sharesForLiquidities);

        assertEq(liquidities1.length, liquidities.length, "test_GetLiquiditiesForSharesAndSharesForLiquidities::3");

        for (uint256 i; i < liquidities1.length; ++i) {
            assertApproxEqRel(
                liquidities1[i], liquidities[i], 1e10, "test_GetLiquiditiesForSharesAndSharesForLiquidities::4"
            );
        }
    }

    function test_GetAmountsAndFeesEarnedOf() public {
        // Make sure the composition of the active id is ~50/50
        swapNbBins(lbPair0, true, 1);

        (uint256[] memory aliceIds, uint256[] memory aliceShares) = addLiquidity(alice, lbPair0, 1e18, 20e6, 4, 4);

        uint256[] memory aliceLiquidities = helper.getLiquiditiesForShares(lbPair0, aliceIds, aliceShares);

        (uint256[] memory aliceAmountsX, uint256[] memory aliceAmountsY) = helper.getAmountsOf(lbPair0, alice, aliceIds);

        (
            uint256[] memory aliceCurrentAmountsX,
            uint256[] memory aliceCurrentAmountsY,
            uint256[] memory aliceFeesX,
            uint256[] memory aliceFeesY
        ) = helper.getAmountsAndFeesEarnedOf(lbPair0, alice, aliceIds, aliceAmountsX, aliceAmountsY);

        for (uint256 i; i < aliceCurrentAmountsX.length; ++i) {
            assertEq(aliceCurrentAmountsX[i], aliceAmountsX[i], "test_GetAmountsAndFeesEarnedOf::1");
            assertEq(aliceCurrentAmountsY[i], aliceAmountsY[i], "test_GetAmountsAndFeesEarnedOf::2");
            assertEq(aliceFeesX[i], 0, "test_GetAmountsAndFeesEarnedOf::3");
            assertEq(aliceFeesY[i], 0, "test_GetAmountsAndFeesEarnedOf::4");
        }

        {
            (uint256[] memory aliceHalfAmountsX, uint256[] memory aliceHalfAmountsY) =
                (new uint256[](aliceAmountsX.length), new uint256[](aliceAmountsX.length));
            for (uint256 i; i < aliceAmountsX.length; ++i) {
                aliceHalfAmountsX[i] = aliceAmountsX[i] / 2;
                aliceHalfAmountsY[i] = aliceAmountsY[i] / 2;
            }

            (aliceCurrentAmountsX, aliceCurrentAmountsY, aliceFeesX, aliceFeesY) =
                helper.getAmountsAndFeesEarnedOf(lbPair0, alice, aliceIds, aliceHalfAmountsX, aliceHalfAmountsY);

            for (uint256 i; i < aliceCurrentAmountsX.length; ++i) {
                assertEq(aliceCurrentAmountsX[i], aliceAmountsX[i], "test_GetAmountsAndFeesEarnedOf::5");
                assertEq(aliceCurrentAmountsY[i], aliceAmountsY[i], "test_GetAmountsAndFeesEarnedOf::6");
                assertApproxEqRel(aliceFeesX[i], aliceHalfAmountsX[i], 1e14, "test_GetAmountsAndFeesEarnedOf::7");
                assertApproxEqRel(aliceFeesY[i], aliceHalfAmountsY[i], 1e14, "test_GetAmountsAndFeesEarnedOf::8");
            }
        }

        uint24 activeId = lbPair0.getActiveId();
        swapNbBins(lbPair0, true, 4);
        swapNbBins(lbPair0, false, 9);
        swapNbBins(lbPair0, true, 5);

        assertEq(activeId, lbPair0.getActiveId(), "test_GetAmountsAndFeesEarnedOf::9");

        (aliceCurrentAmountsX, aliceCurrentAmountsY, aliceFeesX, aliceFeesY) =
            helper.getAmountsAndFeesEarnedOf(lbPair0, alice, aliceIds, aliceAmountsX, aliceAmountsY);

        for (uint256 i; i < aliceCurrentAmountsX.length; ++i) {
            if (aliceIds[i] > activeId) {
                assertGt(aliceCurrentAmountsX[i], aliceAmountsX[i], "test_GetAmountsAndFeesEarnedOf::10");
                assertGt(aliceFeesX[i], 0, "test_GetAmountsAndFeesEarnedOf::11");
            } else if (aliceIds[i] < activeId) {
                assertGt(aliceCurrentAmountsY[i], aliceAmountsY[i], "test_GetAmountsAndFeesEarnedOf::12");
                assertGt(aliceFeesY[i], 0, "test_GetAmountsAndFeesEarnedOf::13");
            } else {
                assertGt(aliceFeesX[i], 0, "test_GetAmountsAndFeesEarnedOf::14");
                assertGt(aliceFeesY[i], 0, "test_GetAmountsAndFeesEarnedOf::15");
            }
        }

        for (uint256 i; i < aliceIds.length; ++i) {
            uint256[] memory singleId = new uint256[](1);
            singleId[0] = aliceIds[i];

            uint256[] memory singleAmountX = new uint256[](1);
            singleAmountX[0] = aliceFeesX[i];

            uint256[] memory singleAmountY = new uint256[](1);
            singleAmountY[0] = aliceFeesY[i];

            uint256[] memory singleFeeShare =
                helper.getSharesForAmounts(lbPair0, singleId, singleAmountX, singleAmountY);

            (uint256 amountX, uint256 amountY) = burnLiquidity(alice, lbPair0, singleId, singleFeeShare);

            assertApproxEqRel(amountX, aliceFeesX[i], 1e15, "test_GetFeeSharesAndFeesEarnedOf::14");
            assertApproxEqAbs(amountY, aliceFeesY[i], 1, "test_GetFeeSharesAndFeesEarnedOf::15");
        }

        // copy current to previous
        for (uint256 i; i < aliceAmountsX.length; ++i) {
            aliceAmountsX[i] = aliceCurrentAmountsX[i];
            aliceAmountsY[i] = aliceCurrentAmountsY[i];
        }

        uint256[] memory aliceCurrentFeesX = new uint256[](aliceAmountsX.length);
        uint256[] memory aliceCurrentFeesY = new uint256[](aliceAmountsX.length);

        (aliceCurrentAmountsX, aliceCurrentAmountsY, aliceCurrentFeesX, aliceCurrentFeesY) =
            helper.getAmountsAndFeesEarnedOf(lbPair0, alice, aliceIds, aliceAmountsX, aliceAmountsY);

        for (uint256 i; i < aliceCurrentAmountsX.length; ++i) {
            assertApproxEqRel(
                aliceCurrentAmountsX[i], aliceAmountsX[i] - aliceFeesX[i], 1e12, "test_GetAmountsAndFeesEarnedOf::16"
            );
            assertEq(aliceCurrentAmountsY[i], aliceAmountsY[i] - aliceFeesY[i], "test_GetAmountsAndFeesEarnedOf::17");
            assertEq(aliceCurrentFeesX[i], 0, "test_GetAmountsAndFeesEarnedOf::18");
            assertEq(aliceCurrentFeesY[i], 0, "test_GetAmountsAndFeesEarnedOf::19");
        }
    }

    function test_GetFeeSharesAndFeesEarnedOf() public {
        // Make sure the composition of the active id is ~50/50
        swapNbBins(lbPair0, true, 1);

        (uint256[] memory aliceIds, uint256[] memory aliceShares) = addLiquidity(alice, lbPair0, 1e18, 20e6, 4, 4);

        uint256[] memory aliceLiquidities = helper.getLiquiditiesForShares(lbPair0, aliceIds, aliceShares);

        (uint256[] memory aliceAmountsX, uint256[] memory aliceAmountsY) = helper.getAmountsOf(lbPair0, alice, aliceIds);

        (uint256[] memory aliceFeeShares, uint256[] memory aliceFeesX, uint256[] memory aliceFeesY) =
            helper.getFeeSharesAndFeesEarnedOf(lbPair0, alice, aliceIds, aliceLiquidities);

        for (uint256 i; i < aliceFeeShares.length; ++i) {
            assertEq(aliceFeeShares[i], 0, "test_GetFeeSharesAndFeesEarnedOf::1");
            assertEq(aliceFeesX[i], 0, "test_GetFeeSharesAndFeesEarnedOf::2");
            assertEq(aliceFeesY[i], 0, "test_GetFeeSharesAndFeesEarnedOf::3");
        }

        {
            uint256[] memory aliceHalfLiquidities = new uint256[](aliceLiquidities.length);
            for (uint256 i; i < aliceLiquidities.length; ++i) {
                aliceHalfLiquidities[i] = aliceLiquidities[i] / 2;
            }

            (uint256[] memory aliceHalfFeeShares, uint256[] memory aliceHalfFeesX, uint256[] memory aliceHalfFeesY) =
                helper.getFeeSharesAndFeesEarnedOf(lbPair0, alice, aliceIds, aliceHalfLiquidities);

            for (uint256 i; i < aliceHalfFeeShares.length; ++i) {
                assertApproxEqRel(
                    aliceHalfFeeShares[i], aliceShares[i] / 2, 1e13, "test_GetFeeSharesAndFeesEarnedOf::4"
                );
                assertApproxEqRel(aliceHalfFeesX[i], aliceAmountsX[i] / 2, 1e13, "test_GetFeeSharesAndFeesEarnedOf::5");
                assertApproxEqRel(aliceHalfFeesY[i], aliceAmountsY[i] / 2, 1e13, "test_GetFeeSharesAndFeesEarnedOf::6");
            }
        }

        uint24 activeId = lbPair0.getActiveId();

        swapNbBins(lbPair0, true, 4);
        swapNbBins(lbPair0, false, 9);
        swapNbBins(lbPair0, true, 5);

        assertEq(activeId, lbPair0.getActiveId(), "test_GetFeeSharesAndFeesEarnedOf::7");

        (aliceFeeShares, aliceFeesX, aliceFeesY) =
            helper.getFeeSharesAndFeesEarnedOf(lbPair0, alice, aliceIds, aliceLiquidities);

        for (uint256 i; i < aliceFeeShares.length; ++i) {
            if (aliceIds[i] > activeId) {
                assertGt(aliceFeeShares[i], 0, "test_GetFeeSharesAndFeesEarnedOf::8");
                assertGt(aliceFeesX[i], 0, "test_GetFeeSharesAndFeesEarnedOf::9");
            } else if (aliceIds[i] < activeId) {
                assertGt(aliceFeeShares[i], 0, "test_GetFeeSharesAndFeesEarnedOf::10");
                assertGt(aliceFeesY[i], 0, "test_GetFeeSharesAndFeesEarnedOf::11");
            } else {
                assertGt(aliceFeesX[i], 0, "test_GetFeeSharesAndFeesEarnedOf::12");
                assertGt(aliceFeesY[i], 0, "test_GetFeeSharesAndFeesEarnedOf::13");
            }
        }

        for (uint256 i; i < aliceIds.length; ++i) {
            uint256[] memory singleId = new uint256[](1);
            singleId[0] = aliceIds[i];

            uint256[] memory singleFeeShare = new uint256[](1);
            singleFeeShare[0] = aliceFeeShares[i];

            (uint256 amountX, uint256 amountY) = burnLiquidity(alice, lbPair0, singleId, singleFeeShare);

            assertEq(amountX, aliceFeesX[i], "test_GetFeeSharesAndFeesEarnedOf::14");
            assertEq(amountY, aliceFeesY[i], "test_GetFeeSharesAndFeesEarnedOf::15");
        }

        (aliceFeeShares, aliceFeesX, aliceFeesY) =
            helper.getFeeSharesAndFeesEarnedOf(lbPair0, alice, aliceIds, aliceLiquidities);

        for (uint256 i; i < aliceFeeShares.length; ++i) {
            assertEq(aliceFeeShares[i], 0, "test_GetFeeSharesAndFeesEarnedOf::16");
            assertEq(aliceFeesX[i], 0, "test_GetFeeSharesAndFeesEarnedOf::17");
            assertEq(aliceFeesY[i], 0, "test_GetFeeSharesAndFeesEarnedOf::18");
        }
    }
}
