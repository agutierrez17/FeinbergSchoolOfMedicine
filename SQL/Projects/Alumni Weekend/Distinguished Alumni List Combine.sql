SELECT
'Society Members' AS "List",
"Org",
"Matched ID",
"CATracks Pref Mail Name",
"Deceased",
"Alumni Flag",
"Affilation" AS "Affiliation",
"Feinberg Degrees",
"Other Degrees",
"Distinction",
"Institution 1",
"Institution 2",
"Membership",
"Elected",
"Role",
"Primary Area",
"Secondary Area",
"Location 1",
"Location 2"
FROM RPT_RVA7647."FSM_ALUMNI_PROF_STUDIES" F
INNER JOIN ENTITY E ON F."Matched ID" = E.ID_NUMBER AND E.RECORD_STATUS_CODE NOT IN ('D')
WHERE
("Feinberg Degrees" LIKE '%4;%' OR "Feinberg Degrees" LIKE '%9;%')
AND
"Deceased" IS NULL

SELECT
'2019 Distinguished' AS "List",
F.*
FROM RPT_RVA7647."FSM_ALUMS_2019" F
