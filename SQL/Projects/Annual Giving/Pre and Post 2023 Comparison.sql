CREATE OR REPLACE VIEW RPT_RVA7647.FSM_GP_AG_STATS AS

WITH AP AS (
SELECT DISTINCT
G."Appeal Code",
G."Appeal Description",
G."Appeal Category",
G."Appeal Date",
G."Fiscal Year"
FROM RPT_RVA7647.FSM_GP_AG_GIFTS G
WHERE
G."Appeal Type" = 'Mail'
),

recipients AS (
SELECT
G2."Appeal Code",
COUNT(DISTINCT G2.ENTITY_ID_NUMBER) AS "Recipients"
FROM RPT_RVA7647.FSM_GP_AG_GIFTS G2
WHERE
G2.APPEAL_SID <> '9718' 
AND 
G2.TRANS_ID_NUMBER IS NULL
AND
G2."Appeal Type" = 'Mail'
GROUP BY
G2."Appeal Code"
),

responses AS (
SELECT
G2."Appeal Code",
COUNT(DISTINCT G2.TRANS_ID_NUMBER) AS "Responses",
COUNT(DISTINCT G2.ENTITY_ID_NUMBER) AS "Unique Donors",
SUM(G2."Gift Amount") AS "Total Raised",
AVG(G2."Gift Amount") AS "Average Gift Amount"
FROM RPT_RVA7647.FSM_GP_AG_GIFTS G2
WHERE
G2.APPEAL_SID <> '9718' 
AND 
G2.TRANS_ID_NUMBER IS NOT NULL
AND
G2."Appeal Type" = 'Mail'
GROUP BY
G2."Appeal Code"
),

dg AS (
SELECT
G2."Appeal Code",
SUM(G2."First Time Donor") AS "New Donors",
SUM(G2."Reactivated Donor") AS "Reactivated"
FROM RPT_RVA7647.FSM_GP_AG_GIFTS G2
WHERE
G2.TRANS_ID_NUMBER IS NOT NULL
AND
G2."Appeal Type" = 'Mail'
GROUP BY
G2."Appeal Code"
),

noapl AS (
SELECT
G2."Appeal Code",
COUNT(DISTINCT G2.TRANS_ID_NUMBER) AS "No Apl Gifts",
SUM(G2."Gift Amount") AS "$ No Apl Gifts"
FROM RPT_RVA7647.FSM_GP_AG_GIFTS G2
WHERE
G2.APPEAL_SID = '9718' 
AND 
G2.TRANS_ID_NUMBER IS NOT NULL
AND
G2."Appeal Type" = 'Mail'
GROUP BY
G2."Appeal Code"
),

SUMS AS (
SELECT
AP."Appeal Code",
AP."Appeal Description",
AP."Appeal Category",
AP."Appeal Date",
AP."Fiscal Year",
recipients."Recipients",
responses."Responses",
responses."Unique Donors",
responses."Total Raised",
responses."Unique Donors" / recipients."Recipients" AS "Response Rate",
dg."New Donors",
dg."Reactivated",
responses."Average Gift Amount",
noapl."No Apl Gifts",
noapl."$ No Apl Gifts"

FROM AP
LEFT OUTER JOIN recipients ON AP."Appeal Code" = recipients."Appeal Code"
LEFT OUTER JOIN responses ON AP."Appeal Code" = responses."Appeal Code"
LEFT OUTER JOIN dg ON AP."Appeal Code" = dg."Appeal Code"
LEFT OUTER JOIN noapl ON AP."Appeal Code" = noapl."Appeal Code"
) 

----- Grateful Patients
SELECT
CASE 
  WHEN "Fiscal Year" < '2023' THEN '2020-2022'
  WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024'
ELSE '' END AS "Time Period",
"Appeal Category",

AVG(SUMS."Recipients") AS "Recipients",
AVG(SUMS."Recipients") - LAG(AVG(SUMS."Recipients")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS recipients_diff,
(AVG(SUMS."Recipients") - LAG(AVG(SUMS."Recipients")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Recipients")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS recipients_diff_percent,

AVG(SUMS."Responses") AS "Responses",
AVG(SUMS."Responses") - LAG(AVG(SUMS."Responses")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS responses_diff,
(AVG(SUMS."Responses") - LAG(AVG(SUMS."Responses")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Responses")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS responses_diff_percent,

AVG(SUMS."Unique Donors") AS "Unique Donors",
AVG(SUMS."Unique Donors") - LAG(AVG(SUMS."Unique Donors")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS unique_diff,
(AVG(SUMS."Unique Donors") - LAG(AVG(SUMS."Unique Donors")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Unique Donors")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS unique_diff_percent,

AVG(SUMS."Total Raised") AS "Total Raised",
AVG(SUMS."Total Raised") - LAG(AVG(SUMS."Total Raised")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS total_diff,
(AVG(SUMS."Total Raised") - LAG(AVG(SUMS."Total Raised")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Total Raised")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS total_diff_percent,

AVG(SUMS."Response Rate") AS "Response Rate",
AVG(SUMS."Response Rate") - LAG(AVG(SUMS."Response Rate")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS resp_rate_diff,
(AVG(SUMS."Response Rate") - LAG(AVG(SUMS."Response Rate")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Response Rate")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS resp_rate_diff_percent,

AVG(SUMS."New Donors") AS "New Donors",
AVG(SUMS."New Donors") - LAG(AVG(SUMS."New Donors")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS new_donors_diff,
(AVG(SUMS."New Donors") - LAG(AVG(SUMS."New Donors")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."New Donors")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS new_don_diff_percent,

AVG(SUMS."Reactivated") AS "Reactivated",
AVG(SUMS."Reactivated") - LAG(AVG(SUMS."Reactivated")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS reactivated_diff,
(AVG(SUMS."Reactivated") - LAG(AVG(SUMS."Reactivated")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Reactivated")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS reactivated_diff_percent,

AVG(SUMS."Average Gift Amount") AS "Average Gift Amount",
AVG(SUMS."Average Gift Amount") - LAG(AVG(SUMS."Average Gift Amount")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS avg_gift_diff,
(AVG(SUMS."Average Gift Amount") - LAG(AVG(SUMS."Average Gift Amount")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Average Gift Amount")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS avg_gift_diff_percent,

AVG(SUMS."No Apl Gifts") AS "No Apl Gifts",
AVG(SUMS."No Apl Gifts") - LAG(AVG(SUMS."No Apl Gifts")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS noapl_gift_diff,
(AVG(SUMS."No Apl Gifts") - LAG(AVG(SUMS."No Apl Gifts")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."No Apl Gifts")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS noapl_gift_diff_percent,

AVG(SUMS."$ No Apl Gifts") AS "$ No Apl Gifts",
AVG(SUMS."$ No Apl Gifts") - LAG(AVG(SUMS."$ No Apl Gifts")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS noapl_dollars_diff,
(AVG(SUMS."$ No Apl Gifts") - LAG(AVG(SUMS."$ No Apl Gifts")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."$ No Apl Gifts")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS noapl_dollars_diff_percent,

AVG(SUMS."Responses") + NVL(AVG(SUMS."No Apl Gifts"),0) AS "Responses + Noapl",
(AVG(SUMS."Responses") + NVL(AVG(SUMS."No Apl Gifts"),0)) - LAG(AVG(SUMS."Responses") + NVL(AVG(SUMS."No Apl Gifts"),0)) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS responses_noapl_diff,
((AVG(SUMS."Responses") + NVL(AVG(SUMS."No Apl Gifts"),0)) - LAG(AVG(SUMS."Responses") + NVL(AVG(SUMS."No Apl Gifts"),0)) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Responses") + NVL(AVG(SUMS."No Apl Gifts"),0)) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS responses_noapl_diff_percent,

AVG(SUMS."Total Raised") + NVL(AVG(SUMS."$ No Apl Gifts"),0) AS "Total Raised + Noapl",
(AVG(SUMS."Total Raised") + NVL(AVG(SUMS."No Apl Gifts"),0)) - LAG(AVG(SUMS."Total Raised") + NVL(AVG(SUMS."No Apl Gifts"),0)) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS total_noapl_diff,
((AVG(SUMS."Total Raised") + NVL(AVG(SUMS."No Apl Gifts"),0)) - LAG(AVG(SUMS."Total Raised") + NVL(AVG(SUMS."No Apl Gifts"),0)) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Total Raised") + NVL(AVG(SUMS."No Apl Gifts"),0)) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS total_noapl_diff_percent

FROM SUMS
WHERE
"Appeal Category" = 'Grateful Patients'

GROUP BY
CASE 
  WHEN "Fiscal Year" < '2023' THEN '2020-2022'
  WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024'
ELSE '' END,
"Appeal Category"

UNION

------Cancer Team
SELECT
CASE 
  WHEN "Fiscal Year" < '2023' THEN '2020-2022'
  WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024'
ELSE '' END AS "Time Period",
"Appeal Category",

AVG(SUMS."Recipients") AS "Recipients",
AVG(SUMS."Recipients") - LAG(AVG(SUMS."Recipients")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS recipients_diff,
(AVG(SUMS."Recipients") - LAG(AVG(SUMS."Recipients")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Recipients")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS recipients_diff_percent,

AVG(SUMS."Responses") AS "Responses",
AVG(SUMS."Responses") - LAG(AVG(SUMS."Responses")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS responses_diff,
(AVG(SUMS."Responses") - LAG(AVG(SUMS."Responses")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Responses")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS responses_diff_percent,

AVG(SUMS."Unique Donors") AS "Unique Donors",
AVG(SUMS."Unique Donors") - LAG(AVG(SUMS."Unique Donors")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS unique_diff,
(AVG(SUMS."Unique Donors") - LAG(AVG(SUMS."Unique Donors")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Unique Donors")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS unique_diff_percent,

AVG(SUMS."Total Raised") AS "Total Raised",
AVG(SUMS."Total Raised") - LAG(AVG(SUMS."Total Raised")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS total_diff,
(AVG(SUMS."Total Raised") - LAG(AVG(SUMS."Total Raised")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Total Raised")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS total_diff_percent,

AVG(SUMS."Response Rate") AS "Response Rate",
AVG(SUMS."Response Rate") - LAG(AVG(SUMS."Response Rate")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS resp_rate_diff,
(AVG(SUMS."Response Rate") - LAG(AVG(SUMS."Response Rate")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Response Rate")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS resp_rate_diff_percent,

AVG(SUMS."New Donors") AS "New Donors",
AVG(SUMS."New Donors") - LAG(AVG(SUMS."New Donors")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS new_donors_diff,
(AVG(SUMS."New Donors") - LAG(AVG(SUMS."New Donors")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."New Donors")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS new_don_diff_percent,

AVG(SUMS."Reactivated") AS "Reactivated",
AVG(SUMS."Reactivated") - LAG(AVG(SUMS."Reactivated")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS reactivated_diff,
(AVG(SUMS."Reactivated") - LAG(AVG(SUMS."Reactivated")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Reactivated")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS reactivated_diff_percent,

AVG(SUMS."Average Gift Amount") AS "Average Gift Amount",
AVG(SUMS."Average Gift Amount") - LAG(AVG(SUMS."Average Gift Amount")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS avg_gift_diff,
(AVG(SUMS."Average Gift Amount") - LAG(AVG(SUMS."Average Gift Amount")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Average Gift Amount")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS avg_gift_diff_percent,

AVG(SUMS."No Apl Gifts") AS "No Apl Gifts",
AVG(SUMS."No Apl Gifts") - LAG(AVG(SUMS."No Apl Gifts")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS noapl_gift_diff,
(AVG(SUMS."No Apl Gifts") - LAG(AVG(SUMS."No Apl Gifts")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."No Apl Gifts")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS noapl_gift_diff_percent,

AVG(SUMS."$ No Apl Gifts") AS "$ No Apl Gifts",
AVG(SUMS."$ No Apl Gifts") - LAG(AVG(SUMS."$ No Apl Gifts")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS noapl_dollars_diff,
(AVG(SUMS."$ No Apl Gifts") - LAG(AVG(SUMS."$ No Apl Gifts")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."$ No Apl Gifts")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS noapl_dollars_diff_percent,

AVG(SUMS."Responses") + NVL(AVG(SUMS."No Apl Gifts"),0) AS "Responses + Noapl",
(AVG(SUMS."Responses") + NVL(AVG(SUMS."No Apl Gifts"),0)) - LAG(AVG(SUMS."Responses") + NVL(AVG(SUMS."No Apl Gifts"),0)) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS responses_noapl_diff,
((AVG(SUMS."Responses") + NVL(AVG(SUMS."No Apl Gifts"),0)) - LAG(AVG(SUMS."Responses") + NVL(AVG(SUMS."No Apl Gifts"),0)) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Responses") + NVL(AVG(SUMS."No Apl Gifts"),0)) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS responses_noapl_diff_percent,

AVG(SUMS."Total Raised") + NVL(AVG(SUMS."$ No Apl Gifts"),0) AS "Total Raised + Noapl",
(AVG(SUMS."Total Raised") + NVL(AVG(SUMS."No Apl Gifts"),0)) - LAG(AVG(SUMS."Total Raised") + NVL(AVG(SUMS."No Apl Gifts"),0)) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS total_noapl_diff,
((AVG(SUMS."Total Raised") + NVL(AVG(SUMS."No Apl Gifts"),0)) - LAG(AVG(SUMS."Total Raised") + NVL(AVG(SUMS."No Apl Gifts"),0)) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Total Raised") + NVL(AVG(SUMS."No Apl Gifts"),0)) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS total_noapl_diff_percent

FROM SUMS
WHERE
"Appeal Category" = 'Cancer Team'

GROUP BY
CASE 
  WHEN "Fiscal Year" < '2023' THEN '2020-2022'
  WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024'
ELSE '' END,
"Appeal Category"

UNION

-----All Appeals
SELECT
CASE 
  WHEN "Fiscal Year" < '2023' THEN '2020-2022'
  WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024'
ELSE '' END AS "Time Period",
'All Appeals' AS "Appeal Category",

AVG(SUMS."Recipients") AS "Recipients",
AVG(SUMS."Recipients") - LAG(AVG(SUMS."Recipients")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS recipients_diff,
(AVG(SUMS."Recipients") - LAG(AVG(SUMS."Recipients")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Recipients")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS recipients_diff_percent,

AVG(SUMS."Responses") AS "Responses",
AVG(SUMS."Responses") - LAG(AVG(SUMS."Responses")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS responses_diff,
(AVG(SUMS."Responses") - LAG(AVG(SUMS."Responses")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Responses")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS responses_diff_percent,

AVG(SUMS."Unique Donors") AS "Unique Donors",
AVG(SUMS."Unique Donors") - LAG(AVG(SUMS."Unique Donors")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS unique_diff,
(AVG(SUMS."Unique Donors") - LAG(AVG(SUMS."Unique Donors")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Unique Donors")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS unique_diff_percent,

AVG(SUMS."Total Raised") AS "Total Raised",
AVG(SUMS."Total Raised") - LAG(AVG(SUMS."Total Raised")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS total_diff,
(AVG(SUMS."Total Raised") - LAG(AVG(SUMS."Total Raised")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Total Raised")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS total_diff_percent,

AVG(SUMS."Response Rate") AS "Response Rate",
AVG(SUMS."Response Rate") - LAG(AVG(SUMS."Response Rate")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS resp_rate_diff,
(AVG(SUMS."Response Rate") - LAG(AVG(SUMS."Response Rate")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Response Rate")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS resp_rate_diff_percent,

AVG(SUMS."New Donors") AS "New Donors",
AVG(SUMS."New Donors") - LAG(AVG(SUMS."New Donors")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS new_donors_diff,
(AVG(SUMS."New Donors") - LAG(AVG(SUMS."New Donors")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."New Donors")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS new_don_diff_percent,

AVG(SUMS."Reactivated") AS "Reactivated",
AVG(SUMS."Reactivated") - LAG(AVG(SUMS."Reactivated")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS reactivated_diff,
(AVG(SUMS."Reactivated") - LAG(AVG(SUMS."Reactivated")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Reactivated")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS reactivated_diff_percent,

AVG(SUMS."Average Gift Amount") AS "Average Gift Amount",
AVG(SUMS."Average Gift Amount") - LAG(AVG(SUMS."Average Gift Amount")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS avg_gift_diff,
(AVG(SUMS."Average Gift Amount") - LAG(AVG(SUMS."Average Gift Amount")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Average Gift Amount")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS avg_gift_diff_percent,

AVG(SUMS."No Apl Gifts") AS "No Apl Gifts",
AVG(SUMS."No Apl Gifts") - LAG(AVG(SUMS."No Apl Gifts")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS noapl_gift_diff,
(AVG(SUMS."No Apl Gifts") - LAG(AVG(SUMS."No Apl Gifts")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."No Apl Gifts")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS noapl_gift_diff_percent,

AVG(SUMS."$ No Apl Gifts") AS "$ No Apl Gifts",
AVG(SUMS."$ No Apl Gifts") - LAG(AVG(SUMS."$ No Apl Gifts")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS noapl_dollars_diff,
(AVG(SUMS."$ No Apl Gifts") - LAG(AVG(SUMS."$ No Apl Gifts")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."$ No Apl Gifts")) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS noapl_dollars_diff_percent,

AVG(SUMS."Responses") + NVL(AVG(SUMS."No Apl Gifts"),0) AS "Responses + Noapl",
(AVG(SUMS."Responses") + NVL(AVG(SUMS."No Apl Gifts"),0)) - LAG(AVG(SUMS."Responses") + NVL(AVG(SUMS."No Apl Gifts"),0)) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS responses_noapl_diff,
((AVG(SUMS."Responses") + NVL(AVG(SUMS."No Apl Gifts"),0)) - LAG(AVG(SUMS."Responses") + NVL(AVG(SUMS."No Apl Gifts"),0)) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Responses") + NVL(AVG(SUMS."No Apl Gifts"),0)) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS responses_noapl_diff_percent,

AVG(SUMS."Total Raised") + NVL(AVG(SUMS."$ No Apl Gifts"),0) AS "Total Raised + Noapl",
(AVG(SUMS."Total Raised") + NVL(AVG(SUMS."No Apl Gifts"),0)) - LAG(AVG(SUMS."Total Raised") + NVL(AVG(SUMS."No Apl Gifts"),0)) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS total_noapl_diff,
((AVG(SUMS."Total Raised") + NVL(AVG(SUMS."No Apl Gifts"),0)) - LAG(AVG(SUMS."Total Raised") + NVL(AVG(SUMS."No Apl Gifts"),0)) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  )) / LAG(AVG(SUMS."Total Raised") + NVL(AVG(SUMS."No Apl Gifts"),0)) OVER (ORDER BY CASE WHEN "Fiscal Year" < '2023' THEN '2020-2022' WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024' ELSE '' END  ) AS total_noapl_diff_percent

FROM SUMS

GROUP BY
CASE 
  WHEN "Fiscal Year" < '2023' THEN '2020-2022'
  WHEN "Fiscal Year" IN ('2023','2024') THEN '2023-2024'
ELSE '' END
  ;
