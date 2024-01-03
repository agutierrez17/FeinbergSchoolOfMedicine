WITH email_delivs as (
SELECT
ER.CONSTITUENT_ID,
ER.RECIPIENT_ID,
COUNT(DISTINCT ER.MESSAGE_ID) AS "Number of Message Deliveries"
FROM ADVANCE_NU_RPT.ENCOMPASS_RECIPIENTS ER 
LEFT OUTER JOIN ADVANCE_NU_RPT.ENCOMPASS_BOUNCES B ON ER.RECIPIENT_ID = B.RECIPIENT_ID AND ER.MESSAGE_ID = B.MESSAGE_ID
WHERE
B.ENCOMPASS_ID IS NULL

GROUP BY
ER.CONSTITUENT_ID,
ER.RECIPIENT_ID
),

email_opens as (
SELECT
EO.RECIPIENT_ID,
COUNT(DISTINCT EO.MESSAGE_ID) AS "Number of Messages Opened",
COUNT(DISTINCT EO.ENCOMPASS_ID) AS "Number of Opens"
FROM ADVANCE_NU_RPT.ENCOMPASS_OPENS EO 

GROUP BY
EO.RECIPIENT_ID
),

email_clicks as (
SELECT
EC.RECIPIENT_ID,
COUNT(DISTINCT EC.MESSAGE_ID) AS "Number of Messages Clicked",
COUNT(DISTINCT EC.LINK_ID) AS "Number of Links Clicked",
COUNT(DISTINCT EC.ENCOMPASS_ID) AS "Number of Clicks"
FROM ADVANCE_NU_RPT.ENCOMPASS_CLICKS EC 

GROUP BY
EC.RECIPIENT_ID
),

email_delivs_365 as (
SELECT
ER.CONSTITUENT_ID,
ER.RECIPIENT_ID,
COUNT(DISTINCT ER.MESSAGE_ID) AS "Number of Deliveries 365"
FROM ADVANCE_NU_RPT.ENCOMPASS_RECIPIENTS ER 
LEFT OUTER JOIN ADVANCE_NU_RPT.ENCOMPASS_BOUNCES B ON ER.RECIPIENT_ID = B.RECIPIENT_ID AND ER.MESSAGE_ID = B.MESSAGE_ID
WHERE
B.ENCOMPASS_ID IS NULL
AND
ER.CONSTITUENT_ID = '0000859558'
AND
TO_DATE(ER.ENCOMPASS_DATE_ADDED,'YYYYMMDD') >= add_months( sysdate, -12 )

GROUP BY
ER.CONSTITUENT_ID,
ER.RECIPIENT_ID
),

email_opens_365 as (
SELECT
EO.RECIPIENT_ID,
COUNT(DISTINCT EO.MESSAGE_ID) AS "Number of Messages Opened 365",
COUNT(DISTINCT EO.ENCOMPASS_ID) AS "Number of Opens 365"
FROM ADVANCE_NU_RPT.ENCOMPASS_OPENS EO 
WHERE
TO_DATE(ENCOMPASS_DATE_ADDED,'YYYYMMDD') >= add_months( sysdate, -12 )

GROUP BY
EO.RECIPIENT_ID
),

email_clicks_365 as (
SELECT
EC.RECIPIENT_ID,
COUNT(DISTINCT EC.MESSAGE_ID) AS "Number of Messages Clicked 365",
COUNT(DISTINCT EC.LINK_ID) AS "Number of Links Clicked 365",
COUNT(DISTINCT EC.ENCOMPASS_ID) AS "Number of Clicks 365"
FROM ADVANCE_NU_RPT.ENCOMPASS_CLICKS EC 
WHERE
TO_DATE(ENCOMPASS_DATE_ADDED,'YYYYMMDD') >= add_months( sysdate, -12 )

GROUP BY
EC.RECIPIENT_ID
),

bounces as (
SELECT
B.RECIPIENT_ID,
COUNT(DISTINCT B.ENCOMPASS_ID) AS "Number of Bounces",
'1' as "Has Bounce"
FROM ADVANCE_NU_RPT.ENCOMPASS_BOUNCES B

GROUP BY
B.RECIPIENT_ID
)

SELECT
email_delivs.constituent_id,
email_delivs.recipient_id,
email_delivs."Number of Message Deliveries",
email_opens."Number of Messages Opened",
email_opens."Number of Opens",
email_clicks."Number of Messages Clicked",
email_clicks."Number of Links Clicked",
email_clicks."Number of Clicks",
email_delivs_365."Number of Deliveries 365",
email_opens_365."Number of Messages Opened 365",
email_opens_365."Number of Opens 365",
email_clicks_365."Number of Messages Clicked 365",
email_clicks_365."Number of Links Clicked 365",
email_clicks_365."Number of Clicks 365",
bounces."Number of Bounces",
bounces."Has Bounce"
FROM email_delivs 
LEFT OUTER JOIN email_opens on email_delivs.recipient_id = email_opens.recipient_id
LEFT OUTER JOIN email_clicks on email_delivs.recipient_id = email_clicks.recipient_id
LEFT OUTER JOIN email_delivs_365 ON email_delivs.recipient_id = email_delivs_365.recipient_id
LEFT OUTER JOIN email_opens_365 on email_delivs.recipient_id = email_opens_365.recipient_id
LEFT OUTER JOIN email_clicks_365 on email_delivs.recipient_id = email_clicks_365.recipient_id
LEFT OUTER JOIN bounces ON email_delivs.recipient_id = bounces.recipient_id
WHERE
email_delivs.CONSTITUENT_ID = '0000859558'
