SELECT
*
FROM FSM_GP_AG_GIFTS
WHERE
LENGTH(ENTITY_ID_NUMBER) = 10
AND
TRANS_ID_NUMBER IS NULL
