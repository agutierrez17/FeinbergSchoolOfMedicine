CREATE OR REPLACE VIEW RPT_RVA7647.FSM_COMMITS AS

-- Outright giftS
SELECT DISTINCT
gft.id_number AS "ID Number",
tx_number AS "Transaction Number",
tx_sequence AS "Sequence",
gft.transaction_type AS "Gift Type Code",
t.short_desc AS "Gift Type Desc", 
date_of_record AS "Gift Date",
fiscal_year AS "Fiscal Year",
credit_amount AS "Gift Amount",
gft.allocation_code AS "Allocation Code",
gft.alloc_short_name AS "Alloc Short Name",
al.long_name AS "Alloc Long Name",
s.short_desc AS "Allocation School",
gft.payment_type AS "Payment Type Code",
p.short_desc AS "Payment Type Desc",
gft.restrict_code AS "Designation Code",
gft.restriction_desc AS "Designation Desc",
gft.appeal_code AS "Appeal Code",
a.description as "Appeal Description",
gft.donor_name AS "Name",
fa."Company Name",
fa."Address Line 1",
fa."Address Line 2",
fa."Address Line 3",
fa."City",
fa."State",
fa.ZIP,
fa."Country",
fp."Phone" as "Phone Number",
fe."Email",
case when e.death_dt > '00000000' then 'Y' else 'N' END AS "Deceased"
From nu_gft_trp_gifttrans gft
Left Join tms_transaction_type t On t.transaction_type_code = gft.transaction_type
Left Join tms_payment_type p On p.payment_type_code = gft.payment_type
left join allocation al on gft.allocation_code = al.allocation_code
left join tms_alloc_school s on gft.alloc_school = s.alloc_school_code
left join appeal_header a on gft.appeal_code = a.appeal_code
left join entity e on gft.id_number = e.id_number
left join fsm_phones fp on e.id_number = fp."ID Number" and fp.rw = 1
left join fsm_emails fe on e.id_number = fe."ID Number" and fe.rw = 1
left join fsm_addresses fa on e.id_number = fa."ID Number" and fa.rw = 1
Where  
tx_gypm_ind = 'G' 
AND
gft.alloc_school = 'FS' 
AND
gft.ASSOCIATED_CODE = 'P'

Union All 

-- Matching gift (matching companies)
Select DISTINCT
match_gift_company_id AS "ID Number",
match_gift_receipt_number AS "Transaction Number",
match_gift_matched_sequence AS "Sequence",
'M' AS "Gift Type Code",
'Matching Gift' AS "Gift Type Desc",
match_gift_date_of_record AS "Gift Date",
match_gift_year_of_giving AS "Fiscal Year",
match_gift_amount AS "Gift Amount",
match_gift_allocation_name AS "Allocation Code",
al.short_name as "Alloc Short Name", 
al.long_name as "Alloc Long Name",
s.short_desc as  "Allocation School",
mg.match_payment_type AS "Payment Type Code",
p.short_desc AS "Payment Type Desc",
gft.restrict_code AS "Designation Code",
gft.restriction_desc AS "Designation Desc",
mg.appeal_code AS "Appeal Code",
a.description as "Appeal Description",
e.pref_mail_name AS "Name",
fa."Company Name",
fa."Address Line 1",
fa."Address Line 2",
fa."Address Line 3",
fa."City",
fa."State",
fa.ZIP,
fa."Country",
fp."Phone" as "Phone Number",
fe."Email",
case when e.death_dt > '00000000' then 'Y' else 'N' END AS "Deceased"
From matching_gift mg
Inner Join (Select id_number, tx_number, restrict_code, restriction_desc From nu_gft_trp_gifttrans where ASSOCIATED_CODE = 'P') gft On mg.match_gift_matched_receipt = gft.tx_number
Left Join tms_payment_type p On p.payment_type_code = mg.match_payment_type
left join allocation al on mg.match_gift_allocation_name = al.allocation_code
left join tms_alloc_school s on mg.match_alloc_school = s.alloc_school_code
left join appeal_header a on mg.appeal_code = a.appeal_code
left join entity e on mg.match_gift_company_id = e.id_number
left join fsm_phones fp on e.id_number = fp."ID Number" and fp.rw = 1
left join fsm_emails fe on e.id_number = fe."ID Number" and fe.rw = 1
left join fsm_addresses fa on e.id_number = fa."ID Number" and fa.rw = 1
WHERE
match_alloc_school = 'FS'

Union All 

-- Pledges, including BE and LE program credit
SELECT DISTINCT
pledge_donor_id AS "ID Number",
pledge_pledge_number AS "Transaction Number",
p.pledge_sequence AS "Sequence",
p.pledge_pledge_type AS "Gift Type",
pt.short_desc AS "Gift Type Desc",
pledge_date_of_record AS "Gift Date",
pledge_year_of_giving AS "Fiscal Year",
p.pledge_amount AS "Gift Amount",
p.pledge_allocation_name AS "Allocation Code",
al.short_name as "Allocation Short Name", 
al.long_name as "Allocation Long Name", 
s.short_desc as "Allocation School",
'' AS "Payment Type Code",
'' AS "Payment Type Desc",
'' AS "Designation Code",
'' AS "Designation Desc",
p.pledge_appeal AS "Appeal Code",
a.description as "Appeal Description",
e.pref_mail_name AS "Name",
fa."Company Name",
fa."Address Line 1",
fa."Address Line 2",
fa."Address Line 3",
fa."City",
fa."State",
fa.ZIP,
fa."Country",
fp."Phone" as "Phone Number",
fe."Email",
case when e.death_dt > '00000000' then 'Y' else 'N' END AS "Deceased"
From pledge p
left join tms_pledge_type pt On pt.pledge_type_code = p.pledge_pledge_type
left join ADVANCE.ALLOCATION al on al.allocation_code = p.pledge_allocation_name
left join tms_alloc_school s on pledge_alloc_school = s.alloc_school_code
left join appeal_header a on p.pledge_appeal = a.appeal_code
left join entity e on p.pledge_donor_id = e.id_number
left join fsm_phones fp on e.id_number = fp."ID Number" and fp.rw = 1
left join fsm_emails fe on e.id_number = fe."ID Number" and fe.rw = 1
left join fsm_addresses fa on e.id_number = fa."ID Number" and fa.rw = 1
WHERE
pledge_alloc_school = 'FS' 
AND
pledge_associated_code = 'P'
;
