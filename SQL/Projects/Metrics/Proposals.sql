WITH CURRENT_FY AS
(SELECT CASE WHEN EXTRACT(MONTH FROM SYSDATE) >= 9
THEN EXTRACT(YEAR FROM SYSDATE)+1
ELSE EXTRACT(YEAR FROM SYSDATE)
END CFY
FROM DUAL
)

SELECT DISTINCT
PE.ID_NUMBER AS "ID Number",
SUBSTR(CONCAT('0000000000',P.PROPOSAL_ID),-10) AS "Proposal ID",
PR.PROSPECT_NAME AS "Prospect Name",
P.PROPOSAL_MANAGER_NAME AS "Proposal Manager",
P.PROPOSAL_ASSIST_NAMES_ALL AS "All Proposal Assists",

CASE 
WHEN (P.ASK_AMT = 0) Then ('$0') 
WHEN (P.ASK_AMT >0 ) and (P.ASK_AMT < 10000) Then ('<$10K') 
WHEN ((P.ASK_AMT >= 10000) and (P.ASK_AMT < 25000)) Then ('$10K-$24K') 
WHEN ((P.ASK_AMT >= 25000) and (P.ASK_AMT < 50000)) Then ('$25K-$49K') 
WHEN ((P.ASK_AMT >= 50000) and (P.ASK_AMT < 100000)) Then ('$50K-$99K') 
WHEN ((P.ASK_AMT >= 100000) and (P.ASK_AMT < 250000)) Then ('$100K-$249K') 
WHEN((P.ASK_AMT >= 250000) and (P.ASK_AMT < 500000)) Then ('$250K-$499K') 
WHEN ((P.ASK_AMT >= 500000) and (P.ASK_AMT < 1000000)) Then ('$500K-$999K') 
WHEN ((P.ASK_AMT >= 1000000) and (P.ASK_AMT < 2000000)) Then ('$1M-$1.9M') 
WHEN ((P.ASK_AMT >= 2000000) and (P.ASK_AMT < 5000000)) Then ('$2M-$4.9M') 
WHEN ((P.ASK_AMT >= 5000000) and (P.ASK_AMT < 10000000)) Then ('$5M-$9.9M') 
WHEN ((P.ASK_AMT >= 10000000) and (P.ASK_AMT < 25000000)) Then ('$10M-$24.9M')
WHEN ((P.ASK_AMT >= 25000000) and (P.ASK_AMT < 50000000)) Then ('$25M-$49.9M')
WHEN ((P.ASK_AMT >= 50000000) and (P.ASK_AMT < 100000000)) Then ('$50M-$99.9M') 
WHEN (P.ASK_AMT >= 100000000) Then ('$100M+') 
ELSE (' ') END AS "Ask Amt Band",
P.PROPOSAL_TYPE_DESC AS "Proposal Type",
PR.STAGE_DESC AS "Stage",
P.PROPOSAL_STATUS_DESC AS "Current Status",
P.ACTIVE_IND AS "Proposal Active Ind",
TO_DATE(CASE WHEN P.INITIAL_CONTRIBUTION_DATE_KEY = 0 THEN 18000101 ELSE P.INITIAL_CONTRIBUTION_DATE_KEY END,'YYYYMMDD') AS "Ask Date(mmddyyyy)",
TO_DATE(CASE WHEN P.STOP_DATE_KEY = 0 THEN 18000101 ELSE P.STOP_DATE_KEY END,'YYYYMMDD') AS "Close Date(mmddyyyy)",
SUBSTR(P.SUBMIT_TYPE_DESC,1,4) AS "Probability",
P.ASK_AMT AS "Ask Amount",
P.ORIGINAL_ASK_AMT AS "Planned Ask Amount",
P.ANTICIPATED_AMT AS "Anticipated Commitment",
P.INITIAL_CONTRIBUTION_AMT AS "Anticipated FY Cash",
P.FUNDING_TYPE_DESC AS "Payment Schedule",
P.GRANTED_AMT AS "Granted Amount",
P.DESCRIPTION AS "Proposal Description"

FROM DM_ARD.DIM_PROPOSAL@catrackstobi P
INNER JOIN CURRENT_FY ON CASE WHEN EXTRACT(MONTH FROM TO_DATE(CASE WHEN P.STOP_DATE_KEY = 0 THEN 18000101 ELSE P.STOP_DATE_KEY END,'YYYYMMDD')) >= 9 THEN EXTRACT(YEAR FROM TO_DATE(CASE WHEN P.STOP_DATE_KEY = 0 THEN 18000101 ELSE P.STOP_DATE_KEY END,'YYYYMMDD'))+1 ELSE EXTRACT(YEAR FROM TO_DATE(CASE WHEN P.STOP_DATE_KEY = 0 THEN 18000101 ELSE P.STOP_DATE_KEY END,'YYYYMMDD')) END = CURRENT_FY.CFY
LEFT OUTER JOIN DM_ARD.DIM_PROSPECT@catrackstobi PR ON P.PROSPECT_ID = PR.PROSPECT_ID AND PR.CURRENT_INDICATOR = 'Y' AND PR.DELETED_FLAG = 'N'
LEFT OUTER JOIN DM_ARD.DIM_PROSPECT_ENTITY@catrackstobi PE ON PR.PROSPECT_ID = PE.PROSPECT_ID AND PE.CURRENT_INDICATOR = 'Y' AND PE.PROSPECT_ACTIVE_IND = 'Y' AND PE.DELETED_FLAG = 'N' AND PE.PRIMARY_IND = 'Y'

WHERE
P.CURRENT_INDICATOR = 'Y'
AND
P.DELETED_FLAG = 'N'
AND
P.PROPOSAL_MANAGER_ID_NUMBER = '0000422646'


ORDER BY
P.ASK_AMT DESC;
