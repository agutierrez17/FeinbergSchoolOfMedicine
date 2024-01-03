with cte as 
 (
   select ID_NUMBER, GivingYear,
      -- returns a sequence without gaps for consecutive years
      first_value(GivingYear) over (partition by ID_number order by GivingYear desc) - GivingYear + 1 as x, 
      -- returns a sequence without gaps
      row_number() over (partition by ID_number order by GivingYear desc) as rn
   from ((
    -- Outright gift
    Select DISTINCT id_number, EXTRACT(YEAR FROM date_of_record) AS GivingYear
    From nu_gft_trp_gifttrans gft
    Where  tx_gypm_ind = 'G' and gft.alloc_school = 'FS'
  ) Union All (
    -- Matching gift matched donors; inner join to add all attributed donor ids
    Select gft.id_number, EXTRACT(YEAR FROM match_gift_date_of_record) AS GivingYear
    From matching_gift mg
    Inner Join (Select id_number, tx_number From nu_gft_trp_gifttrans) gft
      On mg.match_gift_matched_receipt = gft.tx_number
      left join ADVANCE.ALLOCATION a on a.allocation_code = mg.match_gift_allocation_name
    left join tms_alloc_school s on match_alloc_school = s.alloc_school_code
    WHERE
      match_alloc_school = 'FS'
  ) Union All (
    -- Pledges, including BE and LE program credit
    Select pledge_donor_id, EXTRACT(YEAR FROM pledge_date_of_record) AS GivingYear
    From pledge
    Inner Join tms_transaction_type t On t.transaction_type_code = pledge.pledge_pledge_type
    left join ADVANCE.ALLOCATION a on a.allocation_code = pledge.pledge_allocation_name
    left join tms_alloc_school s on pledge_alloc_school = s.alloc_school_code
    WHERE
    pledge_alloc_school = 'FS'
  ))
 ) 
 
 select ID_NUMBER, count(*) AS ConsecutiveGivingYears
from cte
where x = rn  -- no gap
AND 
ID_NUMBER IN (SELECT ID_NUMBER FROM CTE WHERE X = 1 AND GivingYear in ('2022','2023'))
group by ID_NUMBER
 
 ((
    -- Outright gift
    Select DISTINCT id_number, EXTRACT(YEAR FROM date_of_record) AS GivingYear
    From nu_gft_trp_gifttrans gft
    Where  tx_gypm_ind = 'G' and gft.alloc_school = 'FS'
  ) Union All (
    -- Matching gift matched donors; inner join to add all attributed donor ids
    Select gft.id_number, EXTRACT(YEAR FROM match_gift_date_of_record)
    From matching_gift mg
    Inner Join (Select id_number, tx_number From nu_gft_trp_gifttrans) gft
      On mg.match_gift_matched_receipt = gft.tx_number
      left join ADVANCE.ALLOCATION a on a.allocation_code = mg.match_gift_allocation_name
    left join tms_alloc_school s on match_alloc_school = s.alloc_school_code
    WHERE
      match_alloc_school = 'FS'
  ) Union All (
    -- Pledges, including BE and LE program credit
    Select pledge_donor_id, EXTRACT(YEAR FROM pledge_date_of_record)
    From pledge
    Inner Join tms_transaction_type t On t.transaction_type_code = pledge.pledge_pledge_type
    left join ADVANCE.ALLOCATION a on a.allocation_code = pledge.pledge_allocation_name
    left join tms_alloc_school s on pledge_alloc_school = s.alloc_school_code
    WHERE
    pledge_alloc_school = 'FS'
  ))
