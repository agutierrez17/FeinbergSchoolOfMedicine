WITH CURRENT_FY AS
(SELECT CASE WHEN EXTRACT(MONTH FROM SYSDATE) >= 9
THEN EXTRACT(YEAR FROM SYSDATE)+1
ELSE EXTRACT(YEAR FROM SYSDATE)
END CFY
FROM DUAL
),

faculty as (
SELECT DISTINCT
F.ID_NUMBER,
F."dept/div" AS "FSM Dept/Div",
F."rank" AS "FSM Title"
FROM FACULTY_IDS F
INNER JOIN FSM_TRANSACTIONS_DM DM ON F.ID_NUMBER = DM."ID Number"
),

lg as (
SELECT
DM."ID Number",
DM."Entire Amount" AS "Last Gift Amount",
DM."Date(mmddyyyy)" AS "Last Gift Date",
DM."Transaction ID" AS "Last Gift Transaction ID",
DM."Type of Transaction" AS "Last Gift Type",
DM."Allocation Code" || ' - ' || DM."Allocation Short Name" AS "Last Gift Allocation",
ROW_NUMBER() OVER (PARTITION BY "ID Number" ORDER BY "Date(mmddyyyy)" DESC) AS Rw
FROM faculty 
INNER JOIN FSM_TRANSACTIONS_DM DM ON faculty.ID_NUMBER = DM."ID Number"
),

founders as (
SELECT
GCM.ID_NUMBER,
SUBSTR(CURR_GIFT_CLUB_MSHP,INSTR(CURR_GIFT_CLUB_MSHP, 'The Founders', 1),INSTR(SUBSTR(CURR_GIFT_CLUB_MSHP,INSTR(CURR_GIFT_CLUB_MSHP, 'The Founders', 1),60),')',1)) AS "Founders Society"
FROM faculty 
INNER JOIN DM_ARD.DIM_GIFT_CLUB_MEMBERSHIP@catrackstobi GCM ON faculty.ID_NUMBER = GCM.ID_NUMBER
WHERE
CURR_GIFT_CLUB_MSHP LIKE '%Founders Society%' 
AND 
CURR_GIFT_CLUB_MSHP_FLG = 'Y'
),

cash_commit as (
SELECT
faculty.ID_NUMBER,
faculty."FSM Dept/Div",
faculty."FSM Title",
COALESCE(SUM("New Gifts and Commitments"),0) AS "Commits",
COALESCE(SUM("Cash"),0) AS "Cash",
COALESCE(SUM(CASE WHEN "Gift Associated Code" NOT IN ('P','S') AND "New Gifts and Commitments" = 0 AND "Cash" = 0 AND "Type of Transaction" NOT IN ('Straight Pledge') THEN "Entire Amount" ELSE 0 END),0) AS "Assoc Cash",
COALESCE(SUM(CASE WHEN "Gift Associated Code" NOT IN ('P','S') AND "New Gifts and Commitments" = 0 AND "Cash" = 0 THEN "Entire Amount" ELSE 0 END),0) AS "Assoc Commits"
FROM
faculty
INNER JOIN FSM_TRANSACTIONS_DM DM ON faculty.ID_NUMBER = DM."ID Number"
GROUP BY
faculty.ID_NUMBER,
faculty."FSM Dept/Div",
faculty."FSM Title"
)

SELECT DISTINCT
E.ID_NUMBER AS "ID Number",
E.PREF_MAIL_NAME AS "Preferred Mail Name",
cc."Cash" + cc."Assoc Cash" AS "FSM Lifetime Cash Giving",
cc."Commits" + cc."Assoc Commits" AS "FSM Lifetime Commits",
PR.PROSPECT_MANAGER_NAME AS "Prospect Manager",
GCM."Founders Society",
CASE WHEN 
  CASE WHEN EXTRACT(MONTH FROM lg."Last Gift Date") >= 9 THEN EXTRACT(YEAR FROM lg."Last Gift Date")+1 ELSE EXTRACT(YEAR FROM lg."Last Gift Date") END = CFY THEN 'Y' ELSE 'N' END AS "Current Year Donor",
cc."FSM Dept/Div",
cc."FSM Title",
E.PRIMARY_RECORD_TYPE_DESC AS "Record Type Descr",
E.RECORD_STATUS_DESC AS "Record Status Descr",
E.LAST_NAME AS "Last Name",
E.FIRST_NAME AS "First Name",
E.SALUTATION AS "Salutation",
E.INSTITUTIONAL_SUFFIX AS "Institutional Suffix",
E.GENDER_CODE AS "Gender",
E.PREF_CLASS_YEAR AS "Preferred Class Year",
E.PREF_SCHOOL_NAME AS "Preferred School Name",
CASE WHEN E.DEATH_DT <> '00000000' THEN 'Y' ELSE 'N' END AS "Deceased",
E.ADDRESS_STREET1 AS "Address Line 1",
E.ADDRESS_STREET2 AS "Address Line 2",
E.CITY AS "City",
E.STATE_CODE AS "ST",
SUBSTR(E.ZIPCODE,1,5) AS "ZIP",
E.COUNTRY_NAME AS "Country",
EMAIL_ADDRESS AS "Email",
CASE WHEN LENGTH(PHONE_AREA_CODE) = 3 AND LENGTH(PHONE_NUMBER) = 7 THEN '(' || E.PHONE_AREA_CODE || ') ' || SUBSTR(E.PHONE_NUMBER,1,3) || '-' || SUBSTR(E.PHONE_NUMBER,4,4) ELSE E.PHONE_NUMBER END AS "Phone",

lg."Last Gift Amount",
lg."Last Gift Date",
lg."Last Gift Transaction ID",
lg."Last Gift Type",
lg."Last Gift Allocation",

SHS.DO_NOT_SOLICIT_FLAG AS "Do Not Solicit",
SHS.DO_NOT_MAIL_FLAG AS "Do Not Mail",
SHS.DO_NOT_EMAIL_FLAG AS "Do Not Email"

FROM CURRENT_FY,
cash_commit cc
INNER JOIN DM_ARD.DIM_ENTITY@catrackstobi E ON cc.ID_Number = E.ID_NUMBER AND E.CURRENT_INDICATOR = 'Y'
LEFT OUTER JOIN DM_ARD.DIM_SPECIAL_HANDLING_SUMMARY@catrackstobi SHS ON E.ID_NUMBER = SHS.ID_NUMBER
--LEFT OUTER JOIN DM_ARD.FACT_DONOR_SUMMARY@catrackstobi FDSF ON E.ID_NUMBER = FDSF.ENTITY_KEY AND FDSF.ANNUAL_FUND_FLAG = 'N' AND FDSF.REPORTING_AREA = 'FS' 
LEFT OUTER JOIN DM_ARD.DIM_PROSPECT_ENTITY@catrackstobi PE ON E.ID_NUMBER = PE.ID_NUMBER AND PE.CURRENT_INDICATOR = 'Y' AND PE.PROSPECT_ACTIVE_IND = 'Y'
LEFT OUTER JOIN DM_ARD.DIM_PROSPECT@catrackstobi PR ON PE.PROSPECT_ID = PR.PROSPECT_ID AND PR.CURRENT_INDICATOR = 'Y'
LEFT OUTER JOIN founders GCM ON E.ID_NUMBER = GCM.ID_NUMBER
LEFT OUTER JOIN lg ON E.ID_NUMBER = lg."ID Number" AND lg.Rw = 1

--WHERE
--FDSF.FISCAL_YEAR = CURRENT_FY.CFY
--AND
--E.ID_NUMBER IN ('0000369653','0000182908','0000191707','0000369234','0000507058')

ORDER BY
"FSM Lifetime Cash Giving" DESC,
E.LAST_NAME;
