create or replace function rpt_rva7647.fsm_lifetime_giving

       (
       input_id in varchar2
       )

       return NUMBER is
       fsm_lifetime NUMBER(14,2);

begin
with all_transactions as
(
(
select gift.gift_donor_id id_number
, gift.gift_receipt_number transaction_id
, gift.gift_associated_credit_amt amount
, to_char(gift.gift_date_of_record, 'YYYYMMDD') date_of_record
from gift
where gift.pledge_payment_ind <> 'Y'
and gift.gift_transaction_type not in ('40','41','42','43')
and gift.Gift_Alloc_School = 'FS' 
-- and gift_associated_code not in ('M','H')
)
union all
(
select pledge.pledge_donor_id id_number
, pledge.pledge_pledge_number transaction_id
-- BE/LE at face amount
/*, case when primary_pledge.prim_pledge_amount = 0 then 0
    else case when primary_pledge.prim_pledge_status in ('I','R')
    then (pledge_associated_credit_amt*prim_pledge_amount_paid/prim_pledge_amount)  
         else pledge.pledge_associated_credit_amt end end amount*/
-- this is full NGC accounting 
, case when primary_pledge.prim_pledge_amount = 0 then 0
    else case when primary_pledge.prim_pledge_status in ('I','R')
    then (pledge_associated_credit_amt*prim_pledge_amount_paid/prim_pledge_amount)  
         else case when primary_pledge.prim_pledge_type in ('BE','LE')
         then (pledge_associated_credit_amt*discounted_amt/prim_pledge_amount) 
              else pledge.pledge_associated_credit_amt end end end amount
, to_char(pledge.pledge_date_of_record, 'YYYYMMDD') date_of_record
from pledge
inner join primary_pledge on (primary_pledge.prim_pledge_number = pledge.pledge_pledge_number)
WHERE pledge_alloc_school = 'FS' 
)
union all
(
select matching_gift.match_gift_matched_donor_id id_number
, matching_gift.match_gift_receipt_number transaction_id
, matching_gift.match_gift_amount amount
, to_char(matching_gift.match_gift_date_of_record, 'YYYYMMDD') date_of_record
from matching_gift
WHERE match_alloc_school = 'FS'
)
union all
(
select matching_gift.match_gift_company_id id_number
, matching_gift.match_gift_receipt_number transaction_id
, matching_gift.match_gift_amount amount
, to_char(matching_gift.match_gift_date_of_record, 'YYYYMMDD') date_of_record
from matching_gift
where match_gift_company_id <> match_gift_matched_donor_id 
AND match_alloc_school = 'FS'
)
/*union all
(
select historical_summary.hist_id_number id_number
, 'historical soft' transaction_id
, historical_summary.hist_life_asc_amt amount
, '19000101' date_of_record
from historical_summary
)*/
)

, total_giving as
(
select id_number
, sum(amount) life_giving
from all_transactions
group by id_number
)

, life_giving AS
(select total_giving.id_number
, life_giving
from total_giving
inner join entity on (entity.id_number = total_giving.id_number)
left outer join tms_record_status 
     on (tms_record_status.record_status_code = entity.record_status_code)
left outer join tms_record_type 
     on (tms_record_type.record_type_code = entity.record_type_code)
)


select 
life_giving
into fsm_lifetime
from life_giving
where life_giving.id_number = input_id
;


return fsm_lifetime;
end;
