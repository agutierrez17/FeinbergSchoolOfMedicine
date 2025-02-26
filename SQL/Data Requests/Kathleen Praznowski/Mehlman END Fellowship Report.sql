SELECT DISTINCT
E.ID_NUMBER AS "ID Number",
E.REPORT_NAME AS "Report Name",
G.TRANS_ID_NUMBER AS "Transaction ID",
G.YEAR_OF_GIVING AS "Fiscal Year",
TO_DATE(G.DATE_OF_RECORD_KEY,'YYYYMMDD') AS "Date(mmddyyyy)",
    
G.NEW_GIFTS_AND_CMIT_AMT AS "New Gifts and Commitments",
CASE
  WHEN TG.TRANSACTION_SUB_GROUP_CODE IN ('GC') THEN G.OUTRIGHT_GIFT_AMOUNT
  WHEN TG.TRANSACTION_SUB_GROUP_CODE IN ('YC') THEN G.PLEDGE_PAYMENT_AMOUNT
  WHEN TG.TRANSACTION_SUB_GROUP_CODE IN ('MC') THEN G.MATCHING_GIFT_AMOUNT
  ELSE 0.00 END AS "Cash",
    
P.PLEDGE_NUMBER AS "Pledge Number",
CASE
  WHEN G.TRANSACTION_GROUP_SID = 10 AND G.TRANSACTION_TYPE_SID = 0 THEN TG.TRANSACTION_SUB_GROUP_DESC
  WHEN G.PRIMARY_PLEDGE_SID > 0 AND G.TRANSACTION_TYPE_SID = 0 THEN PP.PLEDGE_TYPE_DESC
  ELSE T.TRANSACTION_TYPE_DESC END AS "Type of Transaction",
    
P.PLEDGE_BALANCE AS "Pledge Balance",

AL.ALLOCATION_CODE AS "Allocation Code",
AL.LONG_NAME AS "Allocation Long Name",

G.TRANS_SEQUENCE_NBR,
CASE WHEN P.PLEDGE_NUMBER = ' ' THEN 1000 WHEN 
  CASE
  WHEN G.TRANSACTION_GROUP_SID = 10 AND G.TRANSACTION_TYPE_SID = 0 THEN TG.TRANSACTION_SUB_GROUP_DESC
  WHEN G.PRIMARY_PLEDGE_SID > 0 AND G.TRANSACTION_TYPE_SID = 0 THEN PP.PLEDGE_TYPE_DESC
  ELSE T.TRANSACTION_TYPE_DESC END
    IN ('Non Binding Intent','Bequest Expectancy','Straight Pledge','Telefund Pledge','Recurring Pledge','Grant Pledge')
    THEN 1 ELSE 2 END AS "Pledge Sequence"

FROM DM_ARD.FACT_GIVING_TRANS@catrackstobi G
LEFT OUTER JOIN DM_ARD.DIM_ENTITY@catrackstobi E ON G.ENTITY_ID_NUMBER = E.ID_NUMBER AND E.CURRENT_INDICATOR = 'Y'
LEFT OUTER JOIN DM_ARD.DIM_TRANSACTION_TYPE@catrackstobi T ON G.TRANSACTION_TYPE_SID = T.TRANSACTION_TYPE_SID
LEFT OUTER JOIN DM_ARD.DIM_APPEAL@catrackstobi A ON G.APPEAL_SID = A.APPEAL_SID
LEFT OUTER JOIN DM_ARD.DIM_ALLOCATION@catrackstobi AL ON G.ALLOCATION_SID = AL.ALLOCATION_SID
LEFT OUTER JOIN DM_ARD.DIM_REPORTING_AREA@catrackstobi RA ON G.REPORTING_AREA_SID = RA.REPORTING_AREA_SID
LEFT OUTER JOIN DM_ARD.DIM_PRIMARY_PLEDGE@catrackstobi PP ON G.PRIMARY_PLEDGE_SID = PP.PRIMARY_PLEDGE_SID
LEFT OUTER JOIN DM_ARD.DIM_TRANSACTION_GROUP@catrackstobi TG ON G.TRANSACTION_GROUP_SID = TG.TRANSACTION_GROUP_SID
LEFT OUTER JOIN DM_ARD.DIM_GIFT_ASSOCIATION@catrackstobi GA ON G.GIFT_ASSOCIATED_SID = GA.GIFT_ASSOCIATED_SID
LEFT OUTER JOIN DM_ARD.DIM_PROPOSAL@catrackstobi PR ON G.PROPOSAL_ID = PR.PROPOSAL_ID AND PR.CURRENT_INDICATOR = 'Y'
INNER JOIN DM_ARD.DIM_PRIMARY_PLEDGE@catrackstobi P ON G.PRIMARY_PLEDGE_SID = P.PRIMARY_PLEDGE_SID AND 
      CASE
      WHEN G.TRANSACTION_GROUP_SID = 10 AND G.TRANSACTION_TYPE_SID = 0 THEN TG.TRANSACTION_SUB_GROUP_DESC
      WHEN G.PRIMARY_PLEDGE_SID > 0 AND G.TRANSACTION_TYPE_SID = 0 THEN PP.PLEDGE_TYPE_DESC
      ELSE T.TRANSACTION_TYPE_DESC END IN ('Non Binding Intent','Bequest Expectancy','Straight Pledge','Telefund Pledge','Recurring Pledge','Grant Pledge')
WHERE
G.REPORTING_AREA_SID = '21' ---- FEINBERG
AND
GA.GIFT_ASSOCIATED_CODE NOT IN (/*'C',*/'H','M') -- EXCLUDE SOFT CREDITS, IMO, IHO
AND
AL.ALLOCATION_CODE = '4104005817101END'
AND (
G.NEW_GIFTS_AND_CMIT_AMT > 0
OR
CASE
  WHEN TG.TRANSACTION_SUB_GROUP_CODE IN ('GC') THEN G.OUTRIGHT_GIFT_AMOUNT
  WHEN TG.TRANSACTION_SUB_GROUP_CODE IN ('YC') THEN G.PLEDGE_PAYMENT_AMOUNT
  WHEN TG.TRANSACTION_SUB_GROUP_CODE IN ('MC') THEN G.MATCHING_GIFT_AMOUNT
  ELSE 0.00 END > 0
)

UNION

SELECT DISTINCT
E.ID_NUMBER AS "ID Number",
E.REPORT_NAME AS "Report Name",
G.TRANS_ID_NUMBER AS "Transaction ID",
G.YEAR_OF_GIVING AS "Fiscal Year",
TO_DATE(G.DATE_OF_RECORD_KEY,'YYYYMMDD') AS "Date(mmddyyyy)",
G.NEW_GIFTS_AND_CMIT_AMT AS "New Gifts and Commitments",
CASE
  WHEN TG.TRANSACTION_SUB_GROUP_CODE IN ('GC') THEN G.OUTRIGHT_GIFT_AMOUNT
  WHEN TG.TRANSACTION_SUB_GROUP_CODE IN ('YC') THEN G.PLEDGE_PAYMENT_AMOUNT
  WHEN TG.TRANSACTION_SUB_GROUP_CODE IN ('MC') THEN G.MATCHING_GIFT_AMOUNT
  ELSE 0.00 END AS "Cash",
    
P.PLEDGE_NUMBER AS "Pledge Number",
CASE
  WHEN G.TRANSACTION_GROUP_SID = 10 AND G.TRANSACTION_TYPE_SID = 0 THEN TG.TRANSACTION_SUB_GROUP_DESC
  WHEN G.PRIMARY_PLEDGE_SID > 0 AND G.TRANSACTION_TYPE_SID = 0 THEN PP.PLEDGE_TYPE_DESC
  ELSE T.TRANSACTION_TYPE_DESC END AS "Type of Transaction",
P.PLEDGE_BALANCE AS "Pledge Balance",

AL.ALLOCATION_CODE AS "Allocation Code",
AL.LONG_NAME AS "Allocation Long Name",

G.TRANS_SEQUENCE_NBR,
CASE WHEN P.PLEDGE_NUMBER = ' ' THEN 1000 WHEN 
  CASE
  WHEN G.TRANSACTION_GROUP_SID = 10 AND G.TRANSACTION_TYPE_SID = 0 THEN TG.TRANSACTION_SUB_GROUP_DESC
  WHEN G.PRIMARY_PLEDGE_SID > 0 AND G.TRANSACTION_TYPE_SID = 0 THEN PP.PLEDGE_TYPE_DESC
  ELSE T.TRANSACTION_TYPE_DESC END
    IN ('Non Binding Intent','Bequest Expectancy','Straight Pledge','Telefund Pledge','Recurring Pledge','Grant Pledge')
    THEN 1 ELSE 2 END AS "Pledge Sequence"

FROM DM_ARD.FACT_GIVING_TRANS@catrackstobi G
LEFT OUTER JOIN DM_ARD.DIM_ENTITY@catrackstobi E ON G.ENTITY_ID_NUMBER = E.ID_NUMBER AND E.CURRENT_INDICATOR = 'Y'
LEFT OUTER JOIN DM_ARD.DIM_TRANSACTION_TYPE@catrackstobi T ON G.TRANSACTION_TYPE_SID = T.TRANSACTION_TYPE_SID
LEFT OUTER JOIN DM_ARD.DIM_APPEAL@catrackstobi A ON G.APPEAL_SID = A.APPEAL_SID
LEFT OUTER JOIN DM_ARD.DIM_ALLOCATION@catrackstobi AL ON G.ALLOCATION_SID = AL.ALLOCATION_SID
LEFT OUTER JOIN DM_ARD.DIM_REPORTING_AREA@catrackstobi RA ON G.REPORTING_AREA_SID = RA.REPORTING_AREA_SID
LEFT OUTER JOIN DM_ARD.DIM_PRIMARY_PLEDGE@catrackstobi PP ON G.PRIMARY_PLEDGE_SID = PP.PRIMARY_PLEDGE_SID
LEFT OUTER JOIN DM_ARD.DIM_TRANSACTION_GROUP@catrackstobi TG ON G.TRANSACTION_GROUP_SID = TG.TRANSACTION_GROUP_SID
LEFT OUTER JOIN DM_ARD.DIM_GIFT_ASSOCIATION@catrackstobi GA ON G.GIFT_ASSOCIATED_SID = GA.GIFT_ASSOCIATED_SID
LEFT OUTER JOIN DM_ARD.DIM_PROPOSAL@catrackstobi PR ON G.PROPOSAL_ID = PR.PROPOSAL_ID AND PR.CURRENT_INDICATOR = 'Y'
LEFT OUTER JOIN DM_ARD.DIM_PRIMARY_PLEDGE@catrackstobi P ON G.PRIMARY_PLEDGE_SID = P.PRIMARY_PLEDGE_SID
      
WHERE
G.REPORTING_AREA_SID = '21' ---- FEINBERG
AND
GA.GIFT_ASSOCIATED_CODE NOT IN (/*'C',*/'H','M') -- EXCLUDE SOFT CREDITS, IMO, IHO
AND
AL.ALLOCATION_CODE = '4104005817101END'
AND (
G.NEW_GIFTS_AND_CMIT_AMT > 0
OR
CASE
  WHEN TG.TRANSACTION_SUB_GROUP_CODE IN ('GC') THEN G.OUTRIGHT_GIFT_AMOUNT
  WHEN TG.TRANSACTION_SUB_GROUP_CODE IN ('YC') THEN G.PLEDGE_PAYMENT_AMOUNT
  WHEN TG.TRANSACTION_SUB_GROUP_CODE IN ('MC') THEN G.MATCHING_GIFT_AMOUNT
  ELSE 0.00 END > 0
)
AND
CASE
      WHEN G.TRANSACTION_GROUP_SID = 10 AND G.TRANSACTION_TYPE_SID = 0 THEN TG.TRANSACTION_SUB_GROUP_DESC
      WHEN G.PRIMARY_PLEDGE_SID > 0 AND G.TRANSACTION_TYPE_SID = 0 THEN PP.PLEDGE_TYPE_DESC
      ELSE T.TRANSACTION_TYPE_DESC END NOT IN ('Non Binding Intent','Bequest Expectancy','Straight Pledge','Telefund Pledge','Recurring Pledge','Grant Pledge')

UNION

------ Aggregate all
SELECT DISTINCT
'Summary' AS "ID Number",
' ' AS "Report Name",
' ' AS "Transaction ID",
' ' AS "Fiscal Year",
NULL AS "Date(mmddyyyy)",
SUM(G.NEW_GIFTS_AND_CMIT_AMT) AS "New Gifts and Commitments",
SUM(CASE
  WHEN TG.TRANSACTION_SUB_GROUP_CODE IN ('GC') THEN G.OUTRIGHT_GIFT_AMOUNT
  WHEN TG.TRANSACTION_SUB_GROUP_CODE IN ('YC') THEN G.PLEDGE_PAYMENT_AMOUNT
  WHEN TG.TRANSACTION_SUB_GROUP_CODE IN ('MC') THEN G.MATCHING_GIFT_AMOUNT
  ELSE 0.00 END
) AS "Cash",

' ' AS "Pledge Number",
' ' AS "Type of Transaction",
NULL AS "Pledge Balance",

' ' AS "Allocation Code",
' ' AS "Allocation Long Name",
1000 AS "TRANS_SEQUENCE_NBR",
10000 AS "Pledge Sequence"

FROM DM_ARD.FACT_GIVING_TRANS@catrackstobi G
LEFT OUTER JOIN DM_ARD.DIM_PRIMARY_PLEDGE@catrackstobi P ON G.PRIMARY_PLEDGE_SID = P.PRIMARY_PLEDGE_SID
LEFT OUTER JOIN DM_ARD.DIM_ALLOCATION@catrackstobi AL ON G.ALLOCATION_SID = AL.ALLOCATION_SID
LEFT OUTER JOIN DM_ARD.DIM_GIFT_ASSOCIATION@catrackstobi GA ON G.GIFT_ASSOCIATED_SID = GA.GIFT_ASSOCIATED_SID
LEFT OUTER JOIN DM_ARD.DIM_TRANSACTION_TYPE@catrackstobi T ON G.TRANSACTION_TYPE_SID = T.TRANSACTION_TYPE_SID
LEFT OUTER JOIN DM_ARD.DIM_TRANSACTION_GROUP@catrackstobi TG ON G.TRANSACTION_GROUP_SID = TG.TRANSACTION_GROUP_SID

WHERE
G.REPORTING_AREA_SID = '21' ---- FEINBERG
AND
GA.GIFT_ASSOCIATED_CODE NOT IN (/*'C',*/'H','M') -- EXCLUDE SOFT CREDITS, IMO, IHO
AND
AL.ALLOCATION_CODE = '4104005817101END'

ORDER BY
"Pledge Number" DESC,
"Pledge Sequence",
"Transaction ID",
"TRANS_SEQUENCE_NBR";
