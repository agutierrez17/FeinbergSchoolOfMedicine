---- MAJOR PROSPECT CODE
SELECT DISTINCT
p.MAJOR_PROSPECT_CODE,
T.short_desc AS "Major Prospect Desc"
FROM PROSPECT P
INNER JOIN TMS_MAJOR_PROSPECT T ON P.MAJOR_PROSPECT_CODE = T.major_prospect_code

ORDER BY
p.MAJOR_PROSPECT_CODE


---- PROSPECT STAGE CODE
SELECT DISTINCT
P.STAGE_CODE,
T.short_desc AS "Major Prospect Desc"
FROM PROSPECT P
INNER JOIN TMS_STAGE T ON P.STAGE_CODE = T.STAGE_code

ORDER BY
p.STAGE_CODE
