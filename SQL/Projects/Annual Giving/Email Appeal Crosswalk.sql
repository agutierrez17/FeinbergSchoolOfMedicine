SELECT DISTINCT
RECIPIENT_ID AS FSM_ID,
CONSTITUENT_ID AS ID_NUMBER,
CASE
WHEN MESSAGE_ID IN ('210163288','210177174','210203466') THEN 'KFEG1' --- FY20 Cancer Fall Appeals
  
WHEN MESSAGE_ID = '210178340' THEN 'KFEGE' --- FY20 Grateful Patient Fall Acq 1
WHEN MESSAGE_ID = '210203556' THEN 'KFEG4' --- FY20 Grateful Patient Fall Acq 2
WHEN MESSAGE_ID = '210177978' THEN 'KFEG7' --- FY20 Grateful Patient Fall Renew 1
WHEN MESSAGE_ID = '210203460' THEN 'KWEGB' --- FY20 Grateful Patient Fall Renew 2
  
WHEN MESSAGE_ID IN ('210490584','210504519','210520934','210531804') THEN 'LFEGB' -- FY21 Cancer Fall Appeals

WHEN MESSAGE_ID = '210818432' THEN 'LSEFL' -- FY21 GP Spring 1
WHEN MESSAGE_ID = '210823485' THEN 'LSEFM' -- FY21 GP Spring 2
WHEN MESSAGE_ID = '210829810' THEN 'LSEFN' -- FY21 GP Spring 3
  
WHEN MESSAGE_ID = '210959942' THEN 'MSEFL' -- FY22 GP Fall 1
WHEN MESSAGE_ID = '210993328' THEN 'MSEFM' -- FY22 GP Fall 2
WHEN MESSAGE_ID = '210970683' THEN 'MSEFN' -- FY22 GP Fall 3
WHEN MESSAGE_ID = '210980532' THEN 'MSEFO' -- FY22 GP Fall 4
  
WHEN MESSAGE_ID IN ('211316381','211344113') THEN 'NFBGD' -- FY23 GP Fall Emails
  
WHEN MESSAGE_ID = '211302973' THEN 'NUEG2' -- FY23 Lurie Renewal 1
WHEN MESSAGE_ID = '211316378' THEN 'NUEG3' -- FY23 Lurie Renewal 2
WHEN MESSAGE_ID = '211328286' THEN 'NUEG4' -- FY23 Lurie Renewal 3
WHEN MESSAGE_ID = '211343661' THEN 'NUEG5' -- FY23 Lurie Renewal 4
  
WHEN MESSAGE_ID = '211510745' THEN 'NSEFL' -- FY23 GP Spring 1
WHEN MESSAGE_ID = '211530833' THEN 'NSEFN' -- FY23 GP Spring 3
ELSE '' END AS "Appeal Code",
DESCRIPTION AS "Appeal Description",
CASE WHEN DESCRIPTION LIKE '%Grateful Patient%' THEN 'Grateful Patients' ELSE 'Cancer Team' END AS "Appeal Category",
'Email' AS "Appeal Type",
COALESCE((SELECT MIN(TO_DATE(G.DATE_OF_RECORD_KEY,'YYYYMMDD')) FROM DM_ARD.FACT_GIVING_TRANS@catrackstobi G WHERE G.APPEAL_SID = AP.APPEAL_SID),TO_DATE(AP.DATE_ADDED)) AS "Appeal Date",
CAST('20' || REPLACE(SUBSTR(DESCRIPTION,1,4),'FY','')AS INT) AS "Fiscal Year",
AP.APPEAL_SID
  
FROM ADVANCE_NU_RPT.ENCOMPASS_RECIPIENTS E
INNER JOIN DM_ARD.DIM_APPEAL@catrackstobi AP ON AP.APPEAL_CODE =
CASE
WHEN MESSAGE_ID IN ('210163288','210177174','210203466') THEN 'KFEG1' --- FY20 Cancer Fall Appeals
  
WHEN MESSAGE_ID = '210178340' THEN 'KFEGE' --- FY20 Grateful Patient Fall Acq 1
WHEN MESSAGE_ID = '210203556' THEN 'KFEG4' --- FY20 Grateful Patient Fall Acq 2
WHEN MESSAGE_ID = '210177978' THEN 'KFEG7' --- FY20 Grateful Patient Fall Renew 1
WHEN MESSAGE_ID = '210203460' THEN 'KWEGB' --- FY20 Grateful Patient Fall Renew 2
  
WHEN MESSAGE_ID IN ('210490584','210504519','210520934','210531804') THEN 'LFEGB' -- FY21 Cancer Fall Appeals

WHEN MESSAGE_ID = '210818432' THEN 'LSEFL' -- FY21 GP Spring 1
WHEN MESSAGE_ID = '210823485' THEN 'LSEFM' -- FY21 GP Spring 2
WHEN MESSAGE_ID = '210829810' THEN 'LSEFN' -- FY21 GP Spring 3

WHEN MESSAGE_ID = '210959942' THEN 'MSEFL' -- FY22 GP Fall 1
WHEN MESSAGE_ID = '210993328' THEN 'MSEFM' -- FY22 GP Fall 2
WHEN MESSAGE_ID = '210970683' THEN 'MSEFN' -- FY22 GP Fall 3
WHEN MESSAGE_ID = '210980532' THEN 'MSEFO' -- FY22 GP Fall 4
  
WHEN MESSAGE_ID IN ('211316381','211344113') THEN 'NFBGD' -- FY23 GP Fall Emails
  
WHEN MESSAGE_ID = '211302973' THEN 'NUEG2' -- FY23 Lurie Renewal 1
WHEN MESSAGE_ID = '211316378' THEN 'NUEG3' -- FY23 Lurie Renewal 2
WHEN MESSAGE_ID = '211328286' THEN 'NUEG4' -- FY23 Lurie Renewal 3
WHEN MESSAGE_ID = '211343661' THEN 'NUEG5' -- FY23 Lurie Renewal 4
  
WHEN MESSAGE_ID = '211510745' THEN 'NSEFL' -- FY23 GP Spring 1
WHEN MESSAGE_ID = '211530833' THEN 'NSEFN' -- FY23 GP Spring 3
ELSE '' END
  
WHERE
MESSAGE_ID IN (
'211316381',
'211344113',
'210178340',
'210203556',
'210177978',
'210203460',
'210163288',
'210177174',
'210203466',
'210818432',
'210823485',
'210829810',
'210959942',
'210993328',
'211302973',
'210970683',
'210980532',
'211316378',
'211316381',
'211328286',
'211343661',
'211344113',
'211510745',
'210490584',
'210504519',
'210520934',
'210531804',
'211530833'
);
