SELECT
SUM("New Gifts and Commitments")
FROM FSM_SCHOLARSHIPS
WHERE
ALLOC_DEPT_CODE = '5011050'
AND
"Fiscal Year" >= '2012'
