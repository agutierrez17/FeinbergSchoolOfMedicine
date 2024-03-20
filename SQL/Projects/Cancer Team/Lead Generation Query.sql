CREATE OR REPLACE VIEW FSM_CANCER_LEADS AS

WITH CURRENT_FY AS
(SELECT CASE WHEN EXTRACT(MONTH FROM SYSDATE) >= 9
THEN EXTRACT(YEAR FROM SYSDATE)+1
ELSE EXTRACT(YEAR FROM SYSDATE)
END CFY
FROM DUAL
),

cte as (
select "ID Number", "Fiscal Year",
-- returns a sequence without gaps for consecutive years
first_value("Fiscal Year") over (partition by "ID Number" order by "Fiscal Year" desc) - "Fiscal Year" + 1 as x, 
-- returns a sequence without gaps
row_number() over (partition by "ID Number" order by "Fiscal Year" desc) as rn
from FSM_TRANSACTIONS_DM DM
INNER JOIN FSM_CANCER_ALLOCATIONS FCA ON DM."Allocation Code" = FCA."Allocation Code"

),

cte2 as (
select "ID Number", count(*) AS ConsecutiveGivingYears
from cte
where x = rn  -- no gap
AND 
"ID Number" IN (SELECT "ID Number" FROM CTE WHERE X = 1 AND "Fiscal Year" in (extract(year from sysdate), extract(year from sysdate) -1))
group by "ID Number"
),

lg_notes as (
SELECT
*
FROM FSM_NOTES
WHERE
"Note Type Code" = 'GI'
AND (
"Note Title" LIKE '%Lead Generation%'
OR
"Note Title" LIKE '%lead generation%'
OR
"Note Title" LIKE '%LEAD GENERATION%'
OR
"Note Title" LIKE '%Lead generation%'
))

SELECT DISTINCT
DM."ID Number",
DM."Report Name",
DM."Transaction ID",
DM."Type of Transaction",
DM."Fiscal Year",
DM."Date(mmddyyyy)",
DM."Fiscal Quarter",
DM."New Gifts and Commitments",
DM."Entire Amount",
DM."Cash",
DM."Appeal Code",
DM."Appeal Description",
DM."Appeal Group Code",
DM."Appeal Group Descr",
DM."Appeal Type Code",
DM."Appeal Type Descr",
DM."Appeal Program Code",
DM."Appeal Program Descr",
DM."Allocation Code",
DM."Allocation Short Name",
DM."Allocation Long Name",
DM."Alloc Restricted",
DM."Alloc Fund Name",
DM."Alloc Fund Descr",
DM."Alloc Program Code",
DM."Alloc Program Descr",
DM."Alloc Dept Code",
DM."Alloc Dept Descr",
DM."Tier 1 Purpose Code",
DM."Tier 1 Purpose Descr",
DM."Tier 2 Purpose Code",
DM."Tier 2 Purpose Descr",
DM."Reporting Area Long Name",
DM."Gift Associated Code",
DM."Gift Associated Descr",
DM."Proposal ID",
DM."Proposal Manager",
DM."Record Type Descr",
DM."Preferred Mail Name",
DM."Institutional Suffix",
DM."Salutation",
DM."Last Name",
DM."First Name",
DM."Gender",
DM."Preferred Class Year",
DM."Preferred School Code",
DM."Preferred School Name",
DM."Record Status Code",
DM."Record Status Descr",
DM."Deceased",
DM."Address Line 1",
DM."Address Line 2",
DM."City",
DM."ST",
DM."ZIP",
DM."Country",
DM."Email",
DM."Phone",
DM."Prospect Manager",
DM."Lifetime Giving",
DM."FSM Lifetime Giving",
DM."Wealth Rating",
DM."Major Gift Tier",
DM."Affinity Score",
DM."Do Not Solicit",
DM."Do Not Mail",
DM."Do Not Email",
cte2.ConsecutiveGivingYears AS "Cancer Giving Years",
CASE WHEN DM."ID Number" IN (select DISTINCT ID_NUMBER from ADVANCE.AFFILIATION t WHERE AFFIL_LEVEL_CODE = 'CC' AND AFFIL_STATUS_CODE = 'C') THEN 'Y' ELSE 'N' END AS "Clinic Client Code",
FCR.CONTACT_DATE AS "Contact Date",
FCR.CONTACT_TYPE AS "Contact Type Code",
FCR.CONTACT_TYPE_DESC AS "Contact Type Desc",
FCR.CONTACT_PURPOSE_CODE AS "Contact Purpose Code",
FCR.CONTACT_PURPOSE_DESC AS "Contact Purpose Desc",
FCR.CONTACTER AS "Contacter",
FCR.DESCRIPTION AS "Contact Description",
lg_notes."Contacter" AS "Claimed By"
FROM CURRENT_FY,
FSM_TRANSACTIONS_DM DM
INNER JOIN FSM_CANCER_ALLOCATIONS FCA ON DM."Allocation Code" = FCA."Allocation Code"
LEFT OUTER JOIN cte2 ON DM."ID Number" = cte2."ID Number"
LEFT OUTER JOIN FSM_CONTACT_REPORTS FCR ON DM."ID Number" = FCR.ID_NUMBER AND FCR.Rw = 1
LEFT OUTER JOIN FSM_TRANSACTIONS_DM SC ON DM."Transaction ID" = SC."Transaction ID" AND SC."Gift Associated Code" IN ('C','D') AND SC."Deceased" = 'N'
LEFT OUTER JOIN lg_notes ON DM."ID Number" = lg_notes."ID Number"
WHERE
DM."Fiscal Year" >= CFY - 5
AND
DM."New Gifts and Commitments" > 0
AND
DM."Type of Transaction" NOT IN ('Matching Gift')
AND
SC."ID Number" IS NULL

-----SOFT CREDITS

UNION

SELECT DISTINCT
DM."ID Number",
DM."Report Name",
DM."Transaction ID",
DM."Type of Transaction",
DM."Fiscal Year",
DM."Date(mmddyyyy)",
DM."Fiscal Quarter",
DM."Gift Credit Amount" AS "New Gifts and Commitments",
DM."Entire Amount",
DM."Cash",
DM."Appeal Code",
DM."Appeal Description",
DM."Appeal Group Code",
DM."Appeal Group Descr",
DM."Appeal Type Code",
DM."Appeal Type Descr",
DM."Appeal Program Code",
DM."Appeal Program Descr",
DM."Allocation Code",
DM."Allocation Short Name",
DM."Allocation Long Name",
DM."Alloc Restricted",
DM."Alloc Fund Name",
DM."Alloc Fund Descr",
DM."Alloc Program Code",
DM."Alloc Program Descr",
DM."Alloc Dept Code",
DM."Alloc Dept Descr",
DM."Tier 1 Purpose Code",
DM."Tier 1 Purpose Descr",
DM."Tier 2 Purpose Code",
DM."Tier 2 Purpose Descr",
DM."Reporting Area Long Name",
DM."Gift Associated Code",
DM."Gift Associated Descr",
DM."Proposal ID",
DM."Proposal Manager",
DM."Record Type Descr",
DM."Preferred Mail Name",
DM."Institutional Suffix",
DM."Salutation",
DM."Last Name",
DM."First Name",
DM."Gender",
DM."Preferred Class Year",
DM."Preferred School Code",
DM."Preferred School Name",
DM."Record Status Code",
DM."Record Status Descr",
DM."Deceased",
DM."Address Line 1",
DM."Address Line 2",
DM."City",
DM."ST",
DM."ZIP",
DM."Country",
DM."Email",
DM."Phone",
DM."Prospect Manager",
DM."Lifetime Giving",
DM."FSM Lifetime Giving",
DM."Wealth Rating",
DM."Major Gift Tier",
DM."Affinity Score",
DM."Do Not Solicit",
DM."Do Not Mail",
DM."Do Not Email",
cte2.ConsecutiveGivingYears AS "Cancer Giving Years",
CASE WHEN DM."ID Number" IN (select DISTINCT ID_NUMBER from ADVANCE.AFFILIATION t WHERE AFFIL_LEVEL_CODE = 'CC' AND AFFIL_STATUS_CODE = 'C') THEN 'Y' ELSE 'N' END AS "Clinic Client Code",
FCR.CONTACT_DATE AS "Contact Date",
FCR.CONTACT_TYPE AS "Contact Type Code",
FCR.CONTACT_TYPE_DESC AS "Contact Type Desc",
FCR.CONTACT_PURPOSE_CODE AS "Contact Purpose Code",
FCR.CONTACT_PURPOSE_DESC AS "Contact Purpose Desc",
FCR.CONTACTER AS "Contacter",
FCR.DESCRIPTION AS "Contact Description",
lg_notes."Contacter" AS "Claimed By"
FROM CURRENT_FY,
FSM_TRANSACTIONS_DM DM
INNER JOIN FSM_CANCER_ALLOCATIONS FCA ON DM."Allocation Code" = FCA."Allocation Code"
INNER JOIN FSM_TRANSACTIONS_DM CM ON DM."Transaction ID" = CM."Transaction ID" AND CM."Gift Associated Code" NOT IN ('C','D') AND CM."New Gifts and Commitments" > 0
LEFT OUTER JOIN cte2 ON DM."ID Number" = cte2."ID Number"
LEFT OUTER JOIN FSM_CONTACT_REPORTS FCR ON DM."ID Number" = FCR.ID_NUMBER AND FCR.Rw = 1
LEFT OUTER JOIN lg_notes ON DM."ID Number" = lg_notes."ID Number"
WHERE
DM."Fiscal Year" >= CFY - 5
AND
DM."Type of Transaction" NOT IN ('Matching Gift')
AND
DM."Gift Associated Code" IN ('C','D')
AND
DM."Deceased" = 'N';
