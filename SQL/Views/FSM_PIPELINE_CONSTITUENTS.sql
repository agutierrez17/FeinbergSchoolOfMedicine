CREATE OR REPLACE VIEW RPT_RVA7647.FSM_PIPELINE_CONSTITUENTS AS

SELECT
I.OTHER_ID AS "Pipeline ID",
E.ID_NUMBER AS "CATracks ID",
E.REPORT_NAME as "Prospect Name",
E.LAST_NAME AS "Last Name",
E.FIRST_NAME AS "First Name",
E.INSTITUTIONAL_SUFFIX AS "Institutional Suffix",

----- ADDRESS BLOCK
ADR."Address Line 1",
ADR."Address Line 2",
ADR."Address Line 3",
ADR."City",
ADR."State",
ADR."ZIP",
CASE WHEN ADR."Country" IS NULL THEN 'United States' ELSE ADR."Country" END AS "Country",
PH."Phone",
EM."Email",

----- BIRTHDATE AND AGE
E.BIRTH_DT AS "Birthdate",
CASE WHEN E.BIRTH_DT NOT LIKE '%00%' THEN TRUNC((SYSDATE - TO_DATE(E.BIRTH_DT, 'YYYYMMDD'))/ 365.25) ELSE 0 END AS "Age",
CASE WHEN E.DEATH_DT = '00000000' THEN 'N' ELSE 'Y' END AS "Deceased",

----- RATINGS
MAX(RATING.SHORT_DESC) AS "Wealth Rating",
rpt_rva7647.fsm_lifetime_giving(E.ID_NUMBER) AS "FSM Lifetime Giving",

----- MOST RECENT GIFT INFORMATION
G."Gift Date" AS "Most Recent Gift Date",
G."Gift Amount" AS "Most Recent Gift Amount",
CASE WHEN G."Gift Date" IS NULL THEN NULL ELSE G."Allocation Code" || ' - ' || G."Alloc Short Name" || ' - ' || G."Allocation School" END AS "Most Recent Gift Allocation",

------ MANAGER INFO
MAX(MGR.REPORT_NAME) AS "Manager Name",
MAX(MGR_SPS.REPORT_NAME) AS "Spouse Manager Name",
E.SPOUSE_ID_NUMBER AS "Spouse ID Number",

----- FEINBERG ALUM INFO
CASE WHEN D.ID_NUMBER IS NOT NULL THEN 'Y' ELSE 'N' END AS "Feinberg Alum",
FSMDEGREESLIST(E.ID_NUMBER) AS "FSM Degrees List",
COUNT(DISTINCT D.DEGREE_YEAR) AS "Number of Feinberg Degrees",

----- DEGREE 1 INFO
D1.DEGREE_YEAR AS "Degree 1 Year",
D1."Degree Code" AS "Degree 1 Code",
D1."Degree Code Desc" AS "Degree 1 Type",
D1."Degree Level Desc" AS "Degree 1 Level",
D1."Department Desc" AS "Degree 1 Department",
D1."Concentration Desc" AS "Degree 1 Concentration",

----- DEGREE 2 INFO
D2.DEGREE_YEAR AS "Degree 2 Year",
D2."Degree Code" AS "Degree 2 Code",
D2."Degree Code Desc" AS "Degree 2 Type",
D2."Degree Level Desc" AS "Degree 2 Level",
D2."Department Desc" AS "Degree 2 Department",
D2."Concentration Desc" AS "Degree 2 Concentration",

----- DEGREE 3 INFO
D3.DEGREE_YEAR AS "Degree 3 Year",
D3."Degree Code" AS "Degree 3 Code",
D3."Degree Code Desc" AS "Degree 3 Type",
D3."Degree Level Desc" AS "Degree 3 Level",
D3."Department Desc" AS "Degree 3 Department",
D3."Concentration Desc" AS "Degree 3 Concentration",

----- LAST CONTACT INFO
CT.CONTACT_DATE AS "Most Recent Contact Date",
CT.CONTACT_TYPE_DESC AS "Most Recent Contact Type",
CT.DESCRIPTION AS "Most Recent Contact Descr",
CT.CONTACT_PURPOSE_DESC AS "Most Recent Contact Purpose",
CT.CONTACTER AS "Most Recent Contacter",

----- SPECIAL HANDLING
CASE WHEN E.ID_NUMBER IN (SELECT H.ID_NUMBER FROM HANDLING H WHERE H.HND_TYPE_CODE = 'NC' AND h.hnd_status_code = 'A') THEN 'Y' ELSE 'N' END AS "No Contact",
CASE WHEN E.ID_NUMBER IN (SELECT H.ID_NUMBER FROM HANDLING H WHERE H.HND_TYPE_CODE = 'DNS' AND h.hnd_status_code = 'A') THEN 'Y' ELSE 'N' END AS "No Solicit"

FROM IDS_BASE I
INNER JOIN ENTITY E ON E.ID_NUMBER = I.ID_NUMBER AND I.IDS_TYPE_CODE = 'FPI'
LEFT OUTER JOIN FSM_ADDRESSES ADR ON E.ID_NUMBER = ADR."ID Number" AND ADR.Rw = 1
LEFT OUTER JOIN FSM_PHONES PH ON E.ID_NUMBER = PH."ID Number" AND PH.Rw = 1
LEFT OUTER JOIN FSM_EMAILS eM ON E.ID_NUMBER = EM."ID Number" AND EM.Rw = 1
----- CONSTITUENT PROSPECT AND ASSIGNMENT INFO
LEFT OUTER JOIN PROSPECT_ENTITY PE ON E.ID_NUMBER = PE.ID_NUMBER
LEFT OUTER JOIN PROSPECT P ON PE.PROSPECT_ID = P.PROSPECT_ID
LEFT OUTER JOIN ASSIGNMENT A ON A.PROSPECT_ID = P.PROSPECT_ID AND A.ACTIVE_IND = 'Y' AND A.ASSIGNMENT_TYPE = 'PM'
LEFT OUTER JOIN ENTITY MGR ON A.ASSIGNMENT_ID_NUMBER = MGR.ID_NUMBER
----- SPOUSE PROSPECT AND ASSIGNMENT INFO
LEFT OUTER JOIN PROSPECT_ENTITY PE_SPS ON E.SPOUSE_ID_NUMBER = PE.ID_NUMBER
LEFT OUTER JOIN PROSPECT P_SPS ON PE_SPS.PROSPECT_ID = P_SPS.PROSPECT_ID
LEFT OUTER JOIN ASSIGNMENT A_SPS ON A_SPS.PROSPECT_ID = P_SPS.PROSPECT_ID AND A_SPS.ACTIVE_IND = 'Y' AND A_SPS.ASSIGNMENT_TYPE = 'PM'
LEFT OUTER JOIN ENTITY MGR_SPS ON A_SPS.ASSIGNMENT_ID = MGR_SPS.ID_NUMBER

LEFT OUTER JOIN DEGREES D ON E.ID_NUMBER = D.ID_NUMBER AND D.SCHOOL_CODE = 'MED'

----- DEGREE 1 INFO
LEFT OUTER JOIN FSM_DEGREES D1 ON E.ID_NUMBER = D1.ID_NUMBER AND D1.Rw = 1

----- DEGREE 2 INFO
LEFT OUTER JOIN FSM_DEGREES D2 ON E.ID_NUMBER = D2.ID_NUMBER AND D2.Rw = 2

----- DEGREE 3 INFO
LEFT OUTER JOIN FSM_DEGREES D3 ON E.ID_NUMBER = D3.ID_NUMBER AND D3.Rw = 3

----- GIVING INFO
LEFT OUTER JOIN FSM_COMMITS_SEQ G ON E.ID_NUMBER = G."ID Number" AND G.Rw = 1

----- RATINGS
LEFT OUTER JOIN EVALUATION EV ON E.ID_NUMBER = EV.ID_NUMBER
LEFT OUTER JOIN TMS_RATING RATING ON EV.RATING_CODE = RATING.rating_code

----- MOST RECENT CONTACT INFO
LEFT OUTER JOIN FSM_CONTACT_REPORTS CT ON E.ID_NUMBER = CT.ID_NUMBER AND CT.RW = 1

GROUP BY
I.OTHER_ID,
E.ID_NUMBER,
E.REPORT_NAME,
E.LAST_NAME,
E.FIRST_NAME,
E.INSTITUTIONAL_SUFFIX,

ADR."Address Line 1",
ADR."Address Line 2",
ADR."Address Line 3",
ADR."City",
ADR."State",
ADR."ZIP",
ADR."Country",
PH."Phone",
EM."Email",

E.BIRTH_DT,

D.ID_NUMBER,

D1.DEGREE_YEAR,
D1."Degree Code",
D1."Degree Code Desc",
D1."Degree Level Desc",
D1."Department Desc",
D1."Concentration Desc",

D2.DEGREE_YEAR,
D2."Degree Code",
D2."Degree Code Desc",
D2."Degree Level Desc",
D2."Department Desc",
D2."Concentration Desc",

D3.DEGREE_YEAR,
D3."Degree Code",
D3."Degree Code Desc",
D3."Degree Level Desc",
D3."Department Desc",
D3."Concentration Desc",

G."Gift Date",
G."Gift Amount",
G."Allocation Code" || ' - ' || G."Alloc Short Name" || ' - ' || G."Allocation School",

E.DEATH_DT,

E.SPOUSE_ID_NUMBER,

CT.CONTACT_DATE,
CT.CONTACT_TYPE_DESC,
CT.DESCRIPTION,
CT.CONTACT_PURPOSE_DESC,
CT.CONTACTER;
