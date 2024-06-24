SELECT DISTINCT
"ID Number",
"Gift Officer",
E.LAST_NAME AS "Last Name",
CASE
  WHEN EXTRACT(MONTH FROM SYSDATE) IN ('9','10','11') THEN 'Q1'
  WHEN EXTRACT(MONTH FROM SYSDATE) IN ('12','1','2') THEN 'Q2'
  WHEN EXTRACT(MONTH FROM SYSDATE) IN ('3','4','5') THEN 'Q3'
  WHEN EXTRACT(MONTH FROM SYSDATE) IN ('6','7','8') THEN 'Q4'
  ELSE '' END AS "Quarter",
E.PREF_MAIL_NAME AS "Preferred Mail Name"
FROM FSM_HIERARCHY F
INNER JOIN ENTITY E ON F."ID Number" = E.ID_NUMBER
WHERE
"Gift Officer" IN (
'Christopherson, Andrew',
'Kreller, Mary',
'Sund, Jordan',
'Dillon, Terri',
'Langert, Nicole',
'Lough, Ashley',
'Fragoules, Eric',
'Melin-Rogovin, Michelle',
'Kuhn, Lawrence',
'Maurer,Vic',
'Monaghan, Meghan',
'Mauro, MaryPat',
'Burke, Jenn',
'McCreery, David',
'Praznowski, Kathleen',
'Scaparotti, Tiffany'
)
ORDER BY
"Gift Officer"
