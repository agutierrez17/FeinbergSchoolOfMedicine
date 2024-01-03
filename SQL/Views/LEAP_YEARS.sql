CREATE OR REPLACE VIEW RPT_RVA7647.LEAP_YEARS AS

with x as (
 select 1900 yr from dual
)

select 
yr + (level*4) AS Year
from x
connect by level <= (extract(year from sysdate)+8 - yr)/4

;
