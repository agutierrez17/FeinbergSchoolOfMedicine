SELECT
E.ID_NUMBER,
E.LAST_NAME,
E.FIRST_NAME,
EM.EMPLOYER_UNIT
--T.*
FROM --ADVANCE.AFFILIATION T
--INNER JOIN 
ENTITY E --ON T.ID_NUMBER = E.ID_NUMBER
INNER JOIN EMPLOYMENT EM ON E.ID_NUMBER = EM.ID_NUMBER AND EM.JOB_STATUS_CODE = 'C' AND (EM.EMPLOYER_UNIT = 'MED-NU-FSM Off of Dev & Alumni' OR EM.EMPLOYER_NAME1 = 'NU Feinberg Development and Alumni Relations')
/*WHERE
--ID_NUMBER= '0000422646'
--AND
AFFIL_CODE = 'FS' -- FEINBERG
AND
AFFIL_LEVEL_CODE = 'ES' -- STAFF
AND
AFFIL_STATUS_CODE = 'C' -- CURRENT*/

ORDER BY
LAST_NAME,
FIRST_NAME
