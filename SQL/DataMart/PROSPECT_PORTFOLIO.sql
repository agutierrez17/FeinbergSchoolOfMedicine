CREATE OR REPLACE VIEW RPT_RVA7647.FSM_PORTFOLIO_DM AS

WITH CURRENT_FY AS
(SELECT CASE WHEN EXTRACT(MONTH FROM SYSDATE) >= 9
THEN EXTRACT(YEAR FROM SYSDATE)+1
ELSE EXTRACT(YEAR FROM SYSDATE)
END CFY
FROM DUAL
)


SELECT
------ ENTITY FIELDS
E.ID_NUMBER AS "ID Number",
E.REPORT_NAME AS "Report Name",
E.PRIMARY_RECORD_TYPE_DESC AS "Record Type Descr",
E.PREF_MAIL_NAME AS "Preferred Mail Name",
E.INSTITUTIONAL_SUFFIX AS "Institutional Suffix",
E.SALUTATION AS "Salutation",
E.LAST_NAME AS "Last Name",
E.FIRST_NAME AS "First Name",
E.GENDER_CODE AS "Gender",
E.PREF_CLASS_YEAR AS "Preferred Class Year",
E.PREF_SCHOOL_CODE AS "Preferred School Code",
E.PREF_SCHOOL_NAME AS "Preferred School Name",
E.RECORD_STATUS_CODE AS "Record Status Code",
E.RECORD_STATUS_DESC AS "Record Status Descr",
CASE WHEN E.DEATH_DT <> '00000000' THEN 'Y' ELSE 'N' END AS "Deceased",
E.ADDRESS_STREET1 AS "Address Line 1",
E.ADDRESS_STREET2 AS "Address Line 2",
E.CITY AS "City",
E.STATE_CODE AS "ST",
SUBSTR(E.ZIPCODE,1,5) AS "ZIP",
E.COUNTRY_NAME AS "Countrqy",
EMAIL_ADDRESS AS "Email",
CASE WHEN LENGTH(PHONE_AREA_CODE) = 3 AND LENGTH(PHONE_NUMBER) = 7 THEN '(' || E.PHONE_AREA_CODE || ') ' || SUBSTR(E.PHONE_NUMBER,1,3) || '-' || SUBSTR(E.PHONE_NUMBER,4,4) ELSE E.PHONE_NUMBER END AS "Phone",

----- ADDITIONAL CONSTITUENT INFO
FDS.LIFETIME_GIFT_CREDIT_AMOUNT AS "Lifetime Giving",
FDSF.LIFETIME_GIFT_CREDIT_AMOUNT AS "FSM Lifetime Giving",
E.MAJOR_GIFT_PR_TIER AS "Major Gift Tier",
E.AFFINITY_SCORE AS "Affinity Score",
NVL(SHS.DO_NOT_SOLICIT_FLAG,'N') AS "Do Not Solicit",
NVL(SHS.DO_NOT_MAIL_FLAG,'N') AS "Do Not Mail",
NVL(SHS.DO_NOT_EMAIL_FLAG,'N') AS "Do Not Email",

----- PROSPECT FIELDS
P.PROSPECT_ID AS "Prospect ID",
PE.PRIMARY_IND AS "Primary Prospect",
P.PROSPECT_NAME AS "Prospect Name",
P.PROSPECT_MANAGER_NAME AS "Prospect Manager",
P.PROSPECT_MANAGER_START_DATE AS "Prospect Manager Start Date",
P.PROSPECT_MANAGER_ID_NUMBER AS "Prospect Manager ID",
P.PROSPECT_TYPE AS "Prospect Type Code",
P.PROSPECT_TYPE_DESC AS "Prospect Type Desc",
P.RATING_CODE AS "Rating Code",
P.RATING_DESC AS "Rating Desc",
P.RESEARCH_EVALUATION_CODE AS "Research Evaluation Code",
P.RESEARCH_EVALUATION_DESC AS "Research Evaluation Desc",
P.QUALIFICATION_CODE AS "Qualification Code",
P.QUALIFICATION_DESC AS "Qualification Desc",
P.STAGE_DATE AS "Stage Date",
P.STAGE_CODE AS "Stage Code",
P.STAGE_DESC AS "Stage Desc",
(SELECT COUNT(*) FROM RPT_RVA7647.FSM_PROPOSALS_DM PR WHERE P.PROSPECT_ID = PR."Prospect ID" AND PR."Active" = 'Y') AS "Active Proposals",
P.CONTACT_RPT_LAST_6_MTHS_COUNT AS "Contact Reports Last 6 Months",
P.CONTACT_RPT_LAST_YEAR_COUNT AS "Contact Reports Last Year",
P.CONTACT_RPT_COUNT AS "Contact Reports All Time",
P.VISIT_LAST_YEAR_COUNT AS "Visits Last Year",
P.VISIT_COUNT AS "Visits All Time",
(SELECT MAX(V.CONTACT_DATE) FROM FSM_CONTACT_REPORTS V WHERE E.ID_NUMBER = V.ID_NUMBER AND V.CONTACT_TYPE = 'V' AND V.AUTHOR_ID_NUMBER = P.PROSPECT_MANAGER_ID_NUMBER) AS "Last Visit Date",
P.LAST_PLEDGE_DATE AS "Last Pledge Date",
P.LAST_PLEDGE_PAYMENT_DATE AS "Last Pledge Payment Date",
P.LAST_OUTRIGHT_GIFT_DATE AS "Last Outright Gift Date",
P.ACTIVE_PROG_RATING AS "Active Program Rating",

-----GIFT OFFICER HIERACHY
FH."Vice Dean",
FH."Vice Dean netID",
FH."Team",
FH."Team netID",
FH."Sub-Team",
FH."Sub-Team netID",
FH."Gift Officer",
FH."Gift Officer netID",

-----LAST CONTACT INFO
FCR.CONTACT_DATE AS "Last Contact Date",
FCR.CONTACT_TYPE AS "Last Contact Type Code",
FCR.CONTACT_TYPE_DESC AS "Last Contact Type Desc",
FCR.CONTACT_PURPOSE_CODE AS "Last Contact Purpose Code",
FCR.CONTACT_PURPOSE_DESC AS "Last Contact Purpose Desc",
FCR.DESCRIPTION AS "Last Contact Description",

-----LAST NOTE INFO
N."Note Date" AS "Last Note Date",
N."Note Type Code" AS "Last Note Type Code",
N."Note Type Desc" AS "Last Note Type Desc",
N."Note Title" AS "Last Note Title",
N."Note Description" AS "Last Note Description",
N."Contacter" AS "Last Note Entered By",

-----LAST GIFT INFO
G."Date(mmddyyyy)" AS "Last Gift Date",
CASE WHEN G."Gift Credit Amount" = 0  AND G."New Gifts and Commitments" = 0 THEN G."Entire Amount" WHEN G."Gift Credit Amount" = 0 AND G."New Gifts and Commitments" > 0 THEN G."New Gifts and Commitments" ELSE G."Gift Credit Amount" END AS "Last Gift Amount",
G."Allocation Code" AS "Last Gift Allocation Code",
G."Allocation Long Name" AS "Last Gift Allocation Name",
G."Type of Transaction" AS "Last Gift Type",

-----ALUM INFO
NU_DEGREE_FLAG AS "NU Alum",
FSM_DEGREE_FLAG AS "FSM Alum",
FSM_PRIORITY_DEGREE_YEAR AS "FSM Priority Degree Year",
FSM_PRIORITY_DEGREE_DESCR AS "FSM Priority Degree Descr",
FSM_PRIORITY_DEGREE_CODE AS "FSM Priority Degree Code",
FSM_PRIORITY_MAJOR_1 AS "FSM Priority Major",
FSM_PRIORITY_CONCENTRATION AS "FSM Priority Concentration",

------PROPOSAL INFO
PR."Proposal ID" AS "Last Proposal ID",
PR."Active",
PR."Proposal Manager Name",
PR."Proposal Title",
PR."Proposal Description",
PR."Proposal Status Code",
PR."Proposal Status Desc",
PR."Proposal Start Date",
PR."Proposal Close Date",
PR."Proposal Type Code",
PR."Proposal Type Desc",
PR."Original Ask Amount",
PR."Anticipated Amount",
PR."Ask Amount",
PR."Granted Amount"

FROM DM_ARD.DIM_PROSPECT@catrackstobi P 
LEFT OUTER JOIN DM_ARD.DIM_PROSPECT_ENTITY@catrackstobi PE ON P.PROSPECT_ID = PE.PROSPECT_ID AND PE.CURRENT_INDICATOR = 'Y' AND PE.PROSPECT_ACTIVE_IND = 'Y' AND PE.DELETED_FLAG = 'N'
LEFT OUTER JOIN DM_ARD.DIM_ENTITY@catrackstobi E ON PE.ID_NUMBER = E.ID_NUMBER AND E.CURRENT_INDICATOR = 'Y'
LEFT OUTER JOIN DM_ARD.DIM_SPECIAL_HANDLING_SUMMARY@catrackstobi SHS ON E.ID_NUMBER = SHS.ID_NUMBER
LEFT OUTER JOIN DM_ARD.FACT_DONOR_SUMMARY@catrackstobi FDS ON E.ID_NUMBER = FDS.ENTITY_KEY AND FDS.ANNUAL_FUND_FLAG = 'N' AND FDS.REPORTING_AREA = 'NA' 
LEFT OUTER JOIN DM_ARD.FACT_DONOR_SUMMARY@catrackstobi FDSF ON E.ID_NUMBER = FDSF.ENTITY_KEY AND FDSF.ANNUAL_FUND_FLAG = 'N' AND FDSF.REPORTING_AREA = 'FS' 
LEFT OUTER JOIN CURRENT_FY ON FDS.FISCAL_YEAR = CFY AND FDSF.FISCAL_YEAR = CFY 
LEFT OUTER JOIN FSM_HIERARCHY FH ON FH."ID Number" = P.PROSPECT_MANAGER_ID_NUMBER
LEFT OUTER JOIN FSM_CONTACT_REPORTS FCR ON E.ID_NUMBER = FCR.ID_NUMBER AND FCR.RwF = 1 AND FCR.AUTHOR_ID_NUMBER = P.PROSPECT_MANAGER_ID_NUMBER
LEFT OUTER JOIN FSM_NOTES N ON E.ID_NUMBER = N."ID Number" AND N.Rw = 1 --AND N."Author ID Number" = P.PROSPECT_MANAGER_ID_NUMBER
LEFT OUTER JOIN DM_ARD.DIM_DEGREE_SUMMARY@catrackstobi D ON E.ID_NUMBER = D.ID_NUMBER
LEFT OUTER JOIN FSM_TRANSACTIONS_DM_SEQ G ON E.ID_NUMBER = G."ID Number" AND G.Rw = 1 --AND G."Appeal Code" NOT IN ('AFFIL', 'HOSPF')
LEFT OUTER JOIN RPT_RVA7647.FSM_PROPOSALS_DM PR ON P.PROSPECT_ID = PR."Prospect ID" AND PR.RW = 1

WHERE
P.ACTIVE_IND = 'Y'
AND
P.CURRENT_INDICATOR = 'Y'
AND
P.DELETED_FLAG = 'N'
AND
P.PROSPECT_MANAGER_OFFICE_CODE = 'FS'

ORDER BY
FH."Gift Officer";
