---- PROPOSAL TYPES
SELECT DISTINCT
P.PROPOSAL_TYPE,
T.short_desc AS "Proposal Type Desc"
FROM PROPOSAL P
LEFT OUTER JOIN TMS_PROPOSAL_TYPE T ON P.PROPOSAL_TYPE = T.proposal_type
ORDER BY
PROPOSAL_TYPE


---- PROPOSAL STATUS CODES
SELECT distinct
P.PROPOSAL_STATUS_CODE,
T.short_desc AS "Status Code Desc"
FROM PROPOSAL P
LEFT OUTER JOIN TMS_PROPOSAL_STATUS T ON P.PROPOSAL_STATUS_CODE = T.proposal_status_code
ORDER BY
P.PROPOSAL_STATUS_CODE


---- PROPOSAL STAGE CODE
SELECT DISTINCT
P.STAGE_CODE,
T.SHORT_DESC AS "Proposal Stage Desc"
FROM PROPOSAL P
LEFT OUTER JOIN TMS_PROPOSAL_STAGE T ON P.STAGE_CODE = T.STAGE_CODE
ORDER BY
P.STAGE_CODE
