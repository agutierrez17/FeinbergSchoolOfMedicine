CREATE OR REPLACE VIEW RPT_RVA7647.DAY_NUMBERS AS


with x as (
select 1970 yr from dual
),

calendar AS (
select rownum - 1 as daynum
from dual
connect by rownum < sysdate - to_date('1-sep-1970') + 1
),

fy_starts as (
SELECT
TO_DATE(CONCAT('9/1/',yr + (level)),'MM/DD/YYYY') AS dt,
EXTRACT(YEAR FROM TO_DATE(CONCAT('9/1/',yr + (level)),'MM/DD/YYYY'))+1 as fy
from x
connect by level <= extract(year from sysdate)- yr
),

y AS (
select to_date('1-sep-1970') + daynum as day
from calendar
),

fy AS
(
SELECT 
y.day,
CASE WHEN EXTRACT(MONTH FROM y.day) >= 9
THEN EXTRACT(YEAR FROM y.day)+1
ELSE EXTRACT(YEAR FROM y.day)
END FY
FROM y
),

CURRENT_FY AS
(SELECT CASE WHEN EXTRACT(MONTH FROM SYSDATE) >= 9
THEN EXTRACT(YEAR FROM SYSDATE)+1
ELSE EXTRACT(YEAR FROM SYSDATE)
END CFY
FROM DUAL
)


SELECT
FY.DAY,
fy_starts.FY,
fy_starts.dt as "FY Start",
trunc(FY.day) - trunc(fy_starts.dt) as DayNumber,
TO_CHAR(SYSDATE,'mm/dd/yyyy') AS CD,
trunc(SYSDATE) - trunc(fy2.dt) as CurrentDayNumber
FROM FY
INNER JOIN fy_starts on FY.FY = fy_starts.FY,
CURRENT_FY
INNER JOIN fy_starts fy2 on CURRENT_FY.CFY = fy2.FY

ORDER BY
fy_starts.FY,
DAYNUMBER
;
