CREATE OR REPLACE VIEW RPT_RVA7647.FSM_CONTACT_REPORTS AS

SELECT
C.ID_NUMBER,
C.CONTACT_DATE,
C.CONTACT_TYPE,
TMS_CTYPE.short_desc AS "CONTACT_TYPE_DESC",
C.CONTACT_PURPOSE_CODE,
TMS_CPURP.short_desc AS "CONTACT_PURPOSE_DESC",
C.AUTHOR_ID_NUMBER,
e.report_name As Contacter,
C.DESCRIPTION,
ROW_NUMBER() OVER (PARTITION BY C.ID_NUMBER ORDER BY C.CONTACT_DATE DESC) AS Rw
FROM CONTACT_REPORT C
Inner Join contact_rpt_credit CR On CR.report_id = c.report_id
INNER JOIN ENTITY E ON CR.ID_NUMBER = E.ID_NUMBER
Inner Join tms_contact_rpt_purpose tms_cpurp On tms_cpurp.contact_purpose_code = c.contact_purpose_code
Inner Join tms_contact_rpt_type tms_ctype On tms_ctype.contact_type = c.contact_type

;
