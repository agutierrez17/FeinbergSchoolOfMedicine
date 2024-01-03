SELECT
'Polina' AS "List",
'' AS "Org",
A."ID Number",
A."Preferred Mail Name",
--F."Prominent Person Notes ",
--F."Backup Link(s)",
A."Primary Employer Name",
A."Primary Employment Job Title",
ADDR.STREET1 AS "Pref Addr 1",
ADDR.City AS "Pref City",
ADDR.state_code AS "Pref State",
CASE WHEN addr.zipcode = ' ' THEN addr.foreign_cityzip ELSE addr.zipcode END AS "Pref Zip",
tms_country.short_desc AS "Pref Country",
RPT_RVA7647.FSMDEGREESLIST(A."ID Number") AS "Feinberg Degrees",
DS2.LIFETIME_GIFT_CREDIT_AMOUNT AS "FSM Lifetime Giving",
DS.LIFETIME_GIFT_CREDIT_AMOUNT AS "Total Lifetime Giving",
NULL AS "Membership",
NULL AS "Elected",
NULL AS "Role",
NULL AS "Primary Area",
NULL AS "Secondary Area"

FROM FSM_ACADEMIC_ONLY A
LEFT OUTER JOIN RPT_RVA7647."FSM_ALUMNI_PROF_STUDIES" F ON A."ID Number" = F."Matched ID"
LEFT OUTER JOIN RPT_RVA7647."FSM_ALUMS_2019" F2 ON F2."ID Number" = A."ID Number"
INNER JOIN ENTITY E ON A."ID Number" = E.ID_NUMBER AND E.RECORD_STATUS_CODE NOT IN ('D')
LEFT OUTER JOIN address addr ON addr.id_number = e.id_number AND addr.addr_pref_ind = 'Y' --only preferred addresses
LEFT OUTER JOIN tms_country ON tms_country.country_code = addr.country_code
LEFT OUTER JOIN DM_ARD.FACT_DONOR_SUMMARY@catrackstobi DS ON E.ID_NUMBER = DS.ENTITY_KEY AND DS.REPORTING_AREA = 'NA' AND DS.ANNUAL_FUND_FLAG = 'N' -- ALL NU LIFETIME GIVING
LEFT OUTER JOIN DM_ARD.FACT_DONOR_SUMMARY@catrackstobi DS2 ON E.ID_NUMBER = DS2.ENTITY_KEY AND DS2.REPORTING_AREA = 'FS' AND DS2.ANNUAL_FUND_FLAG = 'N' -- FEINBERG LIFETIME GIVING

WHERE
F."Matched ID" IS NULL
AND
F2."ID Number" IS NULL

ORDER BY
"ID Number"
