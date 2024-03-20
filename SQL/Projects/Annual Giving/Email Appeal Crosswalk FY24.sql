SELECT DISTINCT
"id" AS FSM_ID,
substr('00000000000'|| "constituentId",-10) AS ID_NUMBER,
CASE
WHEN "messageID" IN ('211645273','211658885','211677236','211693662') THEN 'PFDGD' --'PFEGD' -- FY24 GP Fall Appeal 1
--WHEN "messageID" = '211658885' THEN 'PFEGE' -- FY24 GP Fall Appeal 2
--WHEN "messageID" = '211677236' THEN 'PFEGF' -- FY24 GP Fall Appeal 3
  
WHEN "messageID" = '211642550' THEN 'PFEGJ' -- FY24 Derm Appeal 1
WHEN "messageID" = '211658472' THEN 'PFEGK' -- FY24 Derm Appeal 2
  
WHEN "messageID" = '211649065' THEN 'PUEG2' -- FY24 LCC Fall Appeal 1
WHEN "messageID" = '211658007' THEN 'PUEG3' -- FY24 LCC Fall Appeal 2
WHEN "messageID" = '211674288' THEN 'PUEG4' -- FY24 LCC Fall Appeal 3
WHEN "messageID" = '211693734' THEN 'PUEG5' -- FY24 LCC Fall Appeal 4
  
--WHEN "messageID" = '211658779' THEN 'PFEGG' -- FY24 Rheum Email 1
--WHEN "messageID" = '211658780' THEN 'PFEGH' -- FY24 Rheum Email 1
  
WHEN "messageID" = '211658880' THEN 'PFEGL' -- CFAAR
  
--WHEN "messageID" IN ('211674337','211685139','211685140') THEN '3203006286901GFT' --- DGP Student Relief Emergency Fund
ELSE '' END AS "Appeal Code",
CASE 
  WHEN "messageID" IN ('211645273') THEN 'FY24 FSM Grateful Patient Fall Appeal 1st Email Solicitation'
  WHEN "messageID" IN ('211658885') THEN 'FY24 FSM Grateful Patient Fall Appeal 2nd Email Solicitation'
  WHEN "messageID" IN ('211677236') THEN 'FY24 FSM Grateful Patient Fall Appeal 3rd Email Solicitation'
  WHEN "messageID" IN ('211693662') THEN 'FY24 FSM Grateful Patient Fall Appeal 4th Email Solicitation'
ELSE DESCRIPTION END AS "Appeal Description",
CASE WHEN APPEAL_CODE = 'PFEGL' THEN 'Medicine' WHEN DESCRIPTION LIKE '%Grateful Patient%' THEN 'Grateful Patients' ELSE 'Cancer Team' END AS "Appeal Category",
'Email' AS "Appeal Type",
COALESCE((SELECT MIN(TO_DATE(G.DATE_OF_RECORD_KEY,'YYYYMMDD')) FROM DM_ARD.FACT_GIVING_TRANS@catrackstobi G WHERE G.APPEAL_SID = AP.APPEAL_SID),TO_DATE(AP.DATE_ADDED)) AS "Appeal Date",
CAST('20' || REPLACE(SUBSTR(DESCRIPTION,1,4),'FY','')AS INT) AS "Fiscal Year",
AP.APPEAL_SID
  
FROM FSM_ENCOMPASS_RECIPIENTS E
INNER JOIN DM_ARD.DIM_APPEAL@catrackstobi AP ON AP.APPEAL_CODE =
CASE
WHEN "messageID" IN ('211645273','211658885','211677236','211693662') THEN 'PFDGD' --'PFEGD' -- FY24 GP Fall Appeal 1
--WHEN "messageID" = '211658885' THEN 'PFEGE' -- FY24 GP Fall Appeal 2
--WHEN "messageID" = '211677236' THEN 'PFEGF' -- FY24 GP Fall Appeal 3
  
WHEN "messageID" = '211642550' THEN 'PFEGJ' -- FY24 Derm Appeal 1
WHEN "messageID" = '211658472' THEN 'PFEGK' -- FY24 Derm Appeal 2
  
WHEN "messageID" = '211649065' THEN 'PUEG2' -- FY24 LCC Fall Appeal 1
WHEN "messageID" = '211658007' THEN 'PUEG3' -- FY24 LCC Fall Appeal 2
WHEN "messageID" = '211674288' THEN 'PUEG4' -- FY24 LCC Fall Appeal 3
WHEN "messageID" = '211693734' THEN 'PUEG5' -- FY24 LCC Fall Appeal 4
  
--WHEN "messageID" IN ('211658779','211658780') THEN 'PFEGG' -- FY24 Rheum Email 1
--WHEN "messageID" = '211658780' THEN 'PFEGH' -- FY24 Rheum Email 1
--PFEGI
  
WHEN "messageID" = '211658880' THEN 'PFEGL' -- CFAAR
  
ELSE '' END
  

INNER JOIN DM_ARD.DIM_ALLOCATION@catrackstobi AL ON AL.ALLOCATION_CODE = 
CASE 
  WHEN "messageID" IN ('211674337','211685139','211685140') THEN '3203006286901GFT' -- GRATEFUL PATIENT
  WHEN "messageID" IN ('211684256','211684259') THEN '3203006286901GFT' -- OPTHALMOLOGY
  WHEN "messageID" IN ('211658779','211658780') THEN '3203002224201GFT' -- RHEUMATOLOGY
    ELSE '' END
 INNER JOIN DM_ARD.FACT_GIVING_TRANS@catrackstobi G ON AL.ALLOCATION_SID = G.ALLOCATION_SID AND G.ENTITY_ID_NUMBER = substr('00000000000'|| "constituentId",-10) AND TO_DATE(G.DATE_OF_RECORD_KEY,'YYYYMMDD')

--211684256 - Opthalmology past donors
--211684259 - Opthalmology trainees
--211693662 - GP 4 FY24
;
