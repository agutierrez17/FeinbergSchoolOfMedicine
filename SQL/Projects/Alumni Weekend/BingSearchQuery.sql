SELECT
'2019 Distinguished' AS "List",
'' AS "Org",
F."ID Number",
F."Preferred Mail Name",
--F."Prominent Person Notes ",
--F."Backup Link(s)",
F."Primary Employer Name",
F."Primary Employment Job Title",
ADDR.STREET1 AS "Pref Addr 1",
ADDR.City AS "Pref City",
ADDR.state_code AS "Pref State",
CASE WHEN addr.zipcode = ' ' THEN addr.foreign_cityzip ELSE addr.zipcode END AS "Pref Zip",
tms_country.short_desc AS "Pref Country",
--F."Reunion_Year",
RPT_RVA7647.FSMDEGREESLIST(F."ID Number") AS "Feinberg Degrees",
DS2.LIFETIME_GIFT_CREDIT_AMOUNT AS "FSM Lifetime Giving",
DS.LIFETIME_GIFT_CREDIT_AMOUNT AS "Total Lifetime Giving"

FROM RPT_RVA7647."FSM_ALUMS_2019" F
INNER JOIN ENTITY E ON F."ID Number" = E.ID_NUMBER AND E.RECORD_STATUS_CODE NOT IN ('D')
LEFT OUTER JOIN address addr ON addr.id_number = e.id_number AND addr.addr_pref_ind = 'Y' --only preferred addresses
LEFT OUTER JOIN tms_country ON tms_country.country_code = addr.country_code
LEFT OUTER JOIN DM_ARD.FACT_DONOR_SUMMARY@catrackstobi DS ON E.ID_NUMBER = DS.ENTITY_KEY AND DS.REPORTING_AREA = 'NA' AND DS.ANNUAL_FUND_FLAG = 'N' -- ALL NU LIFETIME GIVING
LEFT OUTER JOIN DM_ARD.FACT_DONOR_SUMMARY@catrackstobi DS2 ON E.ID_NUMBER = DS2.ENTITY_KEY AND DS2.REPORTING_AREA = 'FS' AND DS2.ANNUAL_FUND_FLAG = 'N' -- FEINBERG LIFETIME GIVING

WHERE
F."Primary Employment Job Title" LIKE '%Professor%' 
OR
F."Primary Employment Job Title" LIKE '%Dean%'
OR
F."Primary Employment Job Title" LIKE '%Prof%' 


UNION


SELECT DISTINCT
'Society Members' AS "List",
"Org",
"Matched ID" AS "ID Number",
"CATracks Pref Mail Name" AS "Preferred Mail Name",
--NULL AS "Prominent Person Notes",
--NULL AS "Backup Link(s)",
--CASE WHEN "Institution 2" IS NOT NULL THEN "Institution 2" ELSE "Institution 1" END AS "Primary Employer Name",
A.COMPANY_NAME_1 AS "Primary Employer Name",
A.BUSINESS_TITLE AS "Primary Employment Job Title",
ADDR.STREET1 AS "Pref Addr 1",
ADDR.City AS "Pref City",
ADDR.state_code AS "Pref State",
CASE WHEN addr.zipcode = ' ' THEN addr.foreign_cityzip ELSE addr.zipcode END AS "Pref Zip",
tms_country.short_desc AS "Pref Country",
RPT_RVA7647.FSMDEGREESLIST(F."Matched ID") AS "Feinberg Degrees",
DS2.LIFETIME_GIFT_CREDIT_AMOUNT AS "FSM Lifetime Giving",
DS.LIFETIME_GIFT_CREDIT_AMOUNT AS "Total Lifetime Giving"
FROM RPT_RVA7647."FSM_ALUMNI_PROF_STUDIES" F
INNER JOIN ENTITY E ON F."Matched ID" = E.ID_NUMBER AND E.RECORD_STATUS_CODE NOT IN ('D')
LEFT OUTER JOIN ADDRESS A ON E.ID_NUMBER = A.ID_NUMBER AND A.ADDR_TYPE_CODE = 'B' AND A.ADDR_STATUS_CODE = 'A'
LEFT OUTER JOIN address addr ON addr.id_number = e.id_number AND addr.addr_pref_ind = 'Y' --only preferred addresses
LEFT OUTER JOIN tms_country ON tms_country.country_code = addr.country_code
LEFT OUTER JOIN DM_ARD.FACT_DONOR_SUMMARY@catrackstobi DS ON E.ID_NUMBER = DS.ENTITY_KEY AND DS.REPORTING_AREA = 'NA' AND DS.ANNUAL_FUND_FLAG = 'N' -- ALL NU LIFETIME GIVING
LEFT OUTER JOIN DM_ARD.FACT_DONOR_SUMMARY@catrackstobi DS2 ON E.ID_NUMBER = DS2.ENTITY_KEY AND DS2.REPORTING_AREA = 'FS' AND DS2.ANNUAL_FUND_FLAG = 'N' -- FEINBERG LIFETIME GIVING

WHERE
("Feinberg Degrees" LIKE '%4;%' OR "Feinberg Degrees" LIKE '%9;%')
AND
"Deceased" IS NULL

ORDER BY
"ID Number"
