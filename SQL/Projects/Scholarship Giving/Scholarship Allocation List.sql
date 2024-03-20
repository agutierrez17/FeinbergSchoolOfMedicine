SELECT DISTINCT
"Allocation Code",
"Allocation Long Name",
"Tier 1 Purpose",
"Tier 2 Purpose",
ALLOC_DEPT_CODE AS "Alloc Dept Code",
ALLOC_DEPT_DESC AS "Alloc Dept Desc"
FROM FSM_SCHOLARSHIPS

ORDER BY
"Allocation Code"
