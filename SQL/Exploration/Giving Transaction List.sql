((
    -- Outright gift
    Select id_number, tx_number, tx_sequence, t.short_desc AS "Gift Type", date_of_record, credit_amount, gft.allocation_code, gft.alloc_short_name, s.short_desc as "Allocation School"
    From nu_gft_trp_gifttrans gft
    Left Join tms_transaction_type t On t.transaction_type_code = gft.transaction_type
    left join tms_alloc_school s on gft.alloc_school = s.alloc_school_code
    Where  tx_gypm_ind = 'G' and gft.alloc_school = 'FS'
  ) Union All (
    -- Matching gift matching company
    Select match_gift_company_id, match_gift_receipt_number, match_gift_matched_sequence, 'Matching Gift',match_gift_date_of_record, match_gift_amount, match_gift_allocation_name, a.short_name as "Allocation Name", s.short_desc as  "Allocation School"
    From matching_gift mg
    left join ADVANCE.ALLOCATION a on a.allocation_code = mg.match_gift_allocation_name
    left join tms_alloc_school s on match_alloc_school = s.alloc_school_code
    WHERE
      match_alloc_school = 'FS'
  ) Union All (
    -- Matching gift matched donors; inner join to add all attributed donor ids
    Select gft.id_number, match_gift_receipt_number, match_gift_matched_sequence, 'Matching Gift',match_gift_date_of_record, match_gift_amount, match_gift_allocation_name, a.short_name as "Allocation Name", s.short_desc as  "Allocation School"
    From matching_gift mg
    Inner Join (Select id_number, tx_number From nu_gft_trp_gifttrans) gft
      On mg.match_gift_matched_receipt = gft.tx_number
      left join ADVANCE.ALLOCATION a on a.allocation_code = mg.match_gift_allocation_name
    left join tms_alloc_school s on match_alloc_school = s.alloc_school_code
    WHERE
      match_alloc_school = 'FS'
  ) Union All (
    -- Pledges, including BE and LE program credit
    Select pledge_donor_id, pledge_pledge_number, pledge.pledge_sequence, t.short_desc, pledge_date_of_record, pledge.pledge_amount, pledge.pledge_allocation_name, a.short_name as "Allocation Name", s.short_desc as "Allocation School"
    From pledge
    Inner Join tms_transaction_type t On t.transaction_type_code = pledge.pledge_pledge_type
    left join ADVANCE.ALLOCATION a on a.allocation_code = pledge.pledge_allocation_name
    left join tms_alloc_school s on pledge_alloc_school = s.alloc_school_code
    WHERE
    pledge_alloc_school = 'FS'
  ))
