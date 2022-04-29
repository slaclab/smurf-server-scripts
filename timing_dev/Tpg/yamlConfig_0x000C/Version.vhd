------------------------------------------------------------------------------
-- This file is part of 'LCLS2 Timing Core'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'LCLS2 Timing Core', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

package Version is

constant FPGA_VERSION_C : std_logic_vector(31 downto 0) := x"0000000C"; -- MAKE_VERSION

constant BUILD_STAMP_C : string := "AmcCarrierTimingGenerator: Vivado v2016.3 (x86_64) Built Tue Feb 21 08:23:19 PST 2017 by weaver";

end Version;

-------------------------------------------------------------------------------
-- Revision History:
--
-- 11/13/2015 (0x00000001): Initial Release, TPFIFODEPTH  => 12, BEAMSEQDEPTH =>  6, EXPSEQDEPTH  =>  8,
--                          NARRAYSBSA   => 50, txClk on RTM
-- 11/16/2015 (0x00000002): Initial Release, TPFIFODEPTH  => 12, BEAMSEQDEPTH =>  6, EXPSEQDEPTH  =>  18,
--                          NARRAYSBSA   => 50, txClk on RTM, diagnostics, rx/txpolarity
-- 03/17/2016 (0x00000003): externalRefClk, Digital AMC BAY0, TPFIFODEPTH => 0,
--                          NARRAYSBSA   => 50, BEAMSEQDEPTH =>  6, EXPSEQDEPTH => 18,
--                          BSA + RawDiag
-- 03/23/2016 (0x00000004): Upgraded to IPMC v1.1
-- 04/07/2016 (0x00000005): Internal reference
-- 04/13/2016 (0x00000006): Internal reference and new stream encapsulation
-- added Async Messaging
-- 08/05/2016 (0x00000007): External reference (IP=192.168.2.10) txbufferbypass
-- 08/30/2016 (0x00000008): External reference (IP=192.168.2.10) txbufferbypass,
--                          BEAMSEQDEPTH => 16, ALLOWSEQDEPTH => 16
-- 10/14/2016 (0x00000009): Add auto restart option to BSA (one init, multiple
-- dones), change BSA status counters to count up.
-- 01/26/2017 (0x0000000A): Add sevr,fixed field to diagnostic bus.  Encode
-- sevr in bsaActive,AvgDone.
-- 01/31/2017 (0x0000000B): Use BsaCore development branch (sevr,fixed,variances)
-- 02/08/2017 (0x0000000C): Add AmcGenericAdcDacCore
--
-------------------------------------------------------------------------------

