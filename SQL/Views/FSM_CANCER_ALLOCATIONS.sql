CREATE OR REPLACE VIEW FSM_CANCER_ALLOCATIONS AS

SELECT
AL.ALLOCATION_CODE AS "Allocation Code",
AL.ALLOC_SHORT_NAME AS "Allocation Short Name",
AL.LONG_NAME AS "Allocation Long Name",
'Cancer' AS "Group",
AL.RESTRICT_DESC AS "Alloc Restricted",
AL.FUND_NAME AS "Alloc Fund Name",
AL.FUND_DESC AS "Alloc Fund Descr",
AL.PROGRAM_CODE AS "Alloc Program Code",
AL.PROGRAM_DESC AS "Alloc Program Descr",
AL.ALLOC_DEPT_CODE AS "Alloc Dept Code",
AL.ALLOC_DEPT_DESC AS "Alloc Dept Descr",
AL.AGENCY_CODE AS "Tier 1 Purpose Code",
AL.AGENCY_CODE_DESC AS "Tier 1 Purpose Descr",
AL.ALLOC_PURPOSE_CODE AS "Tier 2 Purpose Code",
AL.ALLOC_PURPOSE_DESC AS "Tier 2 Purpose Descr"
FROM DM_ARD.DIM_ALLOCATION@catrackstobi AL
WHERE
AL.ALLOCATION_CODE IN
(SELECT "Allocation Code" FROM FSM_ALLOCATIONS WHERE "Team 1" = 'Cancer' OR "Team 2" = 'Cancer' OR "Team 3" = 'Cancer');
