create or replace view fsm_ids as

---- CLINIC CLIENTS
SELECT DISTINCT
ID_NUMBER
FROM ADVANCE.AFFILIATION 
WHERE 
AFFIL_LEVEL_CODE = 'CC' 
--AND 
--AFFIL_STATUS_CODE = 'C'

UNION

---- FEINBERG AFFILIATION
SELECT DISTINCT
ID_NUMBER
FROM ADVANCE.AFFILIATION 
WHERE 
AFFIL_CODE = 'FS'

UNION

----- "FEINBERG TEAM" PROSPECT
SELECT DISTINCT
PE.ID_NUMBER
FROM PROSPECT_ENTITY PE 
INNER JOIN PROSPECT P ON PE.PROSPECT_ID = P.PROSPECT_ID AND P.PROSPECT_TEAM_CODE = 'FS'

UNION

------ FEINBERG DEGREES
SELECT DISTINCT 
D.ID_NUMBER
FROM DEGREES D 
WHERE
D.SCHOOL_CODE = 'MED'

UNION

----- FEINBERG GIFTS
SELECT DISTINCT
GFT.ID_NUMBER
From nu_gft_trp_gifttrans gft
WHERE
gft.alloc_school = 'FS' 

UNION

----- FEINBERG MATCHES
SELECT DISTINCT
MG.match_gift_company_id
From matching_gift mg
WHERE
match_alloc_school = 'FS'

UNION

----- FEINBERG PLEDGES
SELECT DISTINCT
PLG.PLEDGE_DONOR_ID
From pledge PLG
WHERE
pledge_alloc_school = 'FS' 

UNION

----- FEINBERG INTEREST AREA

select DISTINCT
ID_NUMBER
from ADVANCE_NU_RPT.INTEREST_AREA_DETAIL
WHERE
INTEREST_AREA = 'Feinberg';
