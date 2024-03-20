-------------------------------------------------------------------------------------------------------------------------------------
 /*   Columns Needed
--------------------------------------------------------------------------------------------------------------------------------------

Data for the pull (most is in the attached):

ID number
Spouse ID number
Preferred Mail Name
Preferred Name Sort
Preferred Spouse Mail Name
First Name
Last Name
Salutation
Record Type Code
Record Type Description
Record Status Code
Record Status Description
Institutional Suffix
Degrees
Class Year
Address Type
Company Name
Street Address (1-3)
City
State
Zip
Country
All Phone numbers
All emails
Trustee Flag
Spouse of Trustee Flag
Handling List
Opt Out List
Anonymous Donor
Opt In Only Flag
Opt In List
Active with Restrictions
AWR Groups
Prospect Manager

-------------------------------------------------------------------------------------------------------------------------------------
           Population Selection */
--------------------------------------------------------------------------------------------------------------------------------------

with f_gifts as (
SELECT
A.*,
ROW_NUMBER() OVER (PARTITION BY A."ID Number" ORDER BY A."Gift Date" DESC) AS Rw
FROM
(SELECT DISTINCT * FROM FSM_COMMITS
      WHERE
      "Allocation Code" IN (
      '3203000901101GFT', -- Darren Latimer Fund Neuro Onc
      '3203000940701GFT', -- Brain Tumor Research Gift Fund
      '3203002191001GFT', -- The Brain Tumor Institute
      '3203003625101GFT', -- Mathematical Neuro Oncology
      '3203003906201GFT', -- Wainwright Lab Research Gifts
      '3203005213501GFT', -- Neuro-Oncology Research Fund
      '3203005291301GFT', -- Nervous System Tumor Bank Gif
      '4104004854601END', -- Malnati Miller Endowed Profes
      '4104005557001END' -- Coblentz Family Endowed Fellow
      )
      AND
      MONTHS_BETWEEN(sysdate,"Gift Date") <= 62
      AND
      "Associated Code" = 'C') A
),

f_gifts_seq as (
  SELECT
  FG."ID Number",
  FG."Gift Date",
  FG.Rw,
  FG2."Gift Date" AS "Gift Date 2",
  FG2.Rw AS "Rw 2",
  trunc(FG."Gift Date") - trunc(FG2."Gift Date") AS "Days Since Previous Gift"
  FROM f_gifts FG
  LEFT OUTER JOIN f_gifts FG2 ON FG."ID Number" = FG2."ID Number" AND FG2.RW = FG.RW + 1 AND FG."Gift Date" <> FG2."Gift Date"
  ),

f_alloc as 
(--Donors to the given allocations
      SELECT DISTINCT
      "ID Number",
      SUM("Gift Amount") AS "Sum Total",
      MAX("Gift Date") AS "Last Gift Date",
      COUNT(DISTINCT "Gift Date") AS "Number of Gifts"
      FROM f_gifts
      
      GROUP BY
      "ID Number"
  )  

--------------------------------------------------------------------------------------------------------------------------------------
/*	Restrictions 
    Define everyone who shoul NOT receive the mailing
    Select ID numbers of entities with certain record statuses, handling status codes, mailing list codes, etc
    and union them all together to create a list of those with restrictions specific to this mailing type
*/
--------------------------------------------------------------------------------------------------------------------------------------

		   , restrictions 				as

(  --exclude Purgeable, Deceased, and No Contact record statuses
   select    id_number
	 from    entity e
	where    e.record_status_code in ('X', 'D', 'C')
	union

   --exclude Do Not Solicit, No Contact, Never Engaged, No Mail, No Mail Solicitation
   select    id_number
	 from    handling h
	where    h.hnd_status_code = 'A'
	  and    h.hnd_type_code in (/*'DNS', */'NC', 'NDR', 'NED', 'NM' /*, 'NMS'*/) 
	union 

   --exclude All Communication, All Solicitation, Mail Communication, Mail Solicitation, Feinberg Alumni Annual Giving, No Alumni Communication
   select    id_number
	 from    mailing_list ml
	where    ml.mail_list_status_code = 'A'
	  and    ml.unit_code in (' ', 'FS', 'FSAG', 'FSAR')                                                /*Unit code defines how to apply the mail list code 
                                                                                                        (e.g. I want to be excluded from All Communication from Feinberg (FS))*/
	  and    ml.mail_list_code in ('AC', 'AS', 'MC', 'MS', 'ENF10', 'NAC') 
	  and    ml.mail_list_ctrl_code = 'EXC'                                                             --Those who want to be excluded from the mail list code
	union 

   --Exclude those with the handling code 'Opt in Only', unless they have opted in to this mailing type
(
   select    id_number
	 from    handling h
	where    h.hnd_status_code='A'
	  and    h.hnd_type_code ='OIO' 
	minus
   select    id_number
	 from    mailing_list ml
	where    ml.mail_list_status_code = 'A'
	  and    ml.unit_code in (' ', 'FS', 'FSAG', 'FSAR')
	  and    ml.mail_list_code in ('AC', 'AS', 'MC', 'MS', 'ENF10', 'NAC') 
	  and    ml.mail_list_ctrl_code = 'INC' 
)

   --Exclude trustees and their spouses
	union 
   select    af.id_number
	 from    affiliation af
	where    af.affil_code in ('TR', 'TS')
	  and    af.affil_status_code = 'C'                
	union
   --Exclude enrolled students
   select    af.id_number
	 from    affiliation af
	where    af.affil_status_code = 'E'
	  and    af.affil_level_code like 'A%'
)
--------------------------------------------------------------------------------------------------------------------------------------
/*	Contactable Population */
--------------------------------------------------------------------------------------------------------------------------------------
		   , all_ids 					as 
(  --select everyone from main population minus those in the restrictions
   select    "ID Number"
	 from    f_alloc
	minus
   select    id_number
	 from    restrictions
)

           , hh_list                    as 
(--identify who the primary entity in a household is, so that output is one row per household
--prioritize alumni, then use id_number as a tie-breaker
--modify what is included in the order by (and what gets left joined) depending on what makes sense for request
   select    "ID Number"
     from    (
                 select    all_ids."ID Number"
                         , rank() over(partition by dh.household_id_number 
                                           order by e.record_type_code
                                                  , e.id_number)                                        as rnk
                   from    all_ids
                   join    dm_ard.dim_household@catrackstobi dh
                     on    dh.id_number = all_ids."ID Number"
              left join    entity e 
                     on    e.id_number = all_ids."ID Number"
                  where    e.jnt_mailings_ind <> 'N'
                    and    e.jnt_gifts_ind <> 'N'
                  union
                 select    all_ids."ID Number"
                         , 1                                                                            as rnk
                   from    all_ids
                   join    entity e
                     on    e.id_number = all_ids."ID Number"
                  where    (e.jnt_mailings_ind = 'N' 
                     or    e.jnt_gifts_ind='N')
              )
    where    rnk = 1
)
--------------------------------------------------------------------------------------------------------------------------------------
/*	Additional Columns */
--------------------------------------------------------------------------------------------------------------------------------------
		   , mr_gift_date 				as
(  --identify the most recent gift date to Feinberg
   select    g.gift_donor_id 																			as id_number
		   , max(g.gift_date_of_record) 																as date_of_record
	 from    gift g
	where    g.gift_donor_id in (select "ID Number" from all_ids)                                         --only include contactable for this mailing
	  AND
      G.GIFT_ASSOCIATED_ALLOCATION IN (
      '3203000901101GFT', -- Darren Latimer Fund Neuro Onc
      '3203000940701GFT', -- Brain Tumor Research Gift Fund
      '3203002191001GFT', -- The Brain Tumor Institute
      '3203003625101GFT', -- Mathematical Neuro Oncology
      '3203003906201GFT', -- Wainwright Lab Research Gifts
      '3203005213501GFT', -- Neuro-Oncology Research Fund
      '3203005291301GFT', -- Nervous System Tumor Bank Gif
      '4104004854601END', -- Malnati Miller Endowed Profes
      '4104005557001END' -- Coblentz Family Endowed Fellow
      )
 group by    g.gift_donor_id
)
		   , mr_gift_alloc 				as 
(  --using most recent gift date, identify most recent gift details (allocation, amount, lockbox code)
   select    distinct(mr_gift_date.id_number)
		   , a.allocation_code
		   , a.short_name 																				as allocation
		   , case 
		   		when a.owners not in (' ', 'CUFS') 
				then a.owners 
				else ' ' 
			  end 																						as lock_box
		   , sum(g.gift_associated_credit_amt) 															as gift_credit_amount
		   , rank() over(partition by mr_gift_date.id_number order by a.allocation_code) 				as rnk
	 from    mr_gift_date
	 join    gift g
	   on    (mr_gift_date.date_of_record = g.gift_date_of_record
	  and    mr_gift_date.id_number = g.gift_donor_id)
	 join    allocation a
	   on    (a.allocation_code = g.gift_associated_allocation)
	where    g.gift_alloc_school = 'FS'
 group by    mr_gift_date.id_number
		   , a.allocation_code
		   , a.alloc_dept_code
		   , a.short_name
		   , case 	
		   		when a.owners not in (' ', 'CUFS') 
				then a.owners 
				else ' ' 
			  end
)
 , gift_info          as 
(--for gifts with multiple allocations, show details for up to three allocations
   select    id_number
       , max(decode(rnk,1,allocation_code))                             as alloc_code1
       , max(decode(rnk,1,allocation))                                as allocation1
       , max(decode(rnk,1,lock_box))                                as lock_box1
       , max(decode(rnk,1,gift_credit_amount))                            as gift_credit1
       , max(decode(rnk,2,allocation_code))                             as alloc_code2
       , max(decode(rnk,2,allocation))                                as allocation2
       , max(decode(rnk,2,lock_box))                                as lock_box2
       , max(decode(rnk,2,gift_credit_amount))                            as gift_credit2
       , max(decode(rnk,3,allocation_code))                             as alloc_code3
       , max(decode(rnk,3,allocation))                                as allocation3
       , max(decode(rnk,3,lock_box))                                as lock_box3
       , max(decode(rnk,3,gift_credit_amount))                            as gift_credit3
   from    mr_gift_alloc
 group by    id_number
)

--------------------------------------------------------------------------------------------------------------------------------------
/*	Phone and Email */
--------------------------------------------------------------------------------------------------------------------------------------
 ,email_1           as
 (
  SELECT "ID Number", "Email" as "Email 1", "Email Type Desc" as "Email 1 Type" from fsm_emails where "ID Number" in (select "ID Number" from all_ids) and Rw = 1
 )
 ,email_2           as
 (
  SELECT "ID Number", "Email" as "Email 2", "Email Type Desc" as "Email 2 Type" from fsm_emails where "ID Number" in (select "ID Number" from all_ids) and Rw = 2
 )
 ,phone_1           as
 (
  SELECT "ID Number", "Phone" as "Phone 1", "Phone Type Desc" as "Phone 1 Type" from fsm_phones where "ID Number" in (select "ID Number" from all_ids) and Rw = 1
 )
 ,phone_2           as
 (
  SELECT "ID Number", "Phone" as "Phone 2", "Phone Type Desc" as "Phone 2 Type" from fsm_phones where "ID Number" in (select "ID Number" from all_ids) and Rw = 2
 )
 ,phone_3           as
 (
  SELECT "ID Number", "Phone" as "Phone 3", "Phone Type Desc" as "Phone 3 Type" from fsm_phones where "ID Number" in (select "ID Number" from all_ids) and Rw = 3
 )
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*  Report Output */
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

select    
vpm.id_number,
sp_vpm.id_number as spouse_id_number,
vpm.pref_mail_name,
case
  when trunc(sysdate) - trunc(f."Last Gift Date") <= 365 then 20
  when trunc(sysdate) - trunc(f."Last Gift Date") <= 730 then 15
  when trunc(sysdate) - trunc(f."Last Gift Date") <= 1095 then 10
  when trunc(sysdate) - trunc(f."Last Gift Date") <= 1445 then 5
  ELSE 0
END
+
case 
  when f."Number of Gifts" > 2 THEN 20
  when f."Number of Gifts" = 2 THEN 10
  ELSE 0
END
+
case 
  when f."Sum Total" >= 100000 THEN 20
  when f."Sum Total" >= 10000 THEN 15
  when f."Sum Total" >= 1000 THEN 10
  when f."Sum Total" >= 100 THEN 5
  else 0
END AS "RFM Score",
trunc(sysdate) - trunc(f."Last Gift Date") AS "Days Since Last Gift",
case
  when trunc(sysdate) - trunc(f."Last Gift Date") <= 365 then 20
  when trunc(sysdate) - trunc(f."Last Gift Date") <= 730 then 15
  when trunc(sysdate) - trunc(f."Last Gift Date") <= 1095 then 10
  when trunc(sysdate) - trunc(f."Last Gift Date") <= 1445 then 5
  ELSE 0
END AS "Recency Score",
F."Number of Gifts",
case 
  when f."Number of Gifts" > 2 THEN 20
  when f."Number of Gifts" = 2 THEN 10
  ELSE 0
END AS "Frequency Score",
F."Sum Total",
case 
  when f."Sum Total" >= 100000 THEN 20
  when f."Sum Total" >= 10000 THEN 15
  when f."Sum Total" >= 1000 THEN 10
  when f."Sum Total" >= 100 THEN 5
  else 0
END AS "Monetary Score"

       , sp_vpm.pref_mail_name                                                                      as spouse_pref_mail_name
       , CASE WHEN M."Import ID" IS NOT NULL THEN 'Y' ELSE 'N' END AS "NMF List"
       , m."Name"
       , M."Address Line 1"
       , e.last_name
       , vpm.first_name
       --, vpm.salutation
       --, sp_vpm.salutation                                                                          as spouse_salutation
       , NU_BIO_PKG_SALUTATIONS.GetLastNameSal(vpm.id_number, sp_vpm.id_number)                     as jnt_salutation
       , vpm.record_type_desc
       --, sp_vpm.record_type_desc                                                                    as spouse_record_type_desc
       , vpm.record_status_desc
       --, sp_vpm.record_status_desc                                                                  as spouse_record_status_desc
       , vpm.institutional_suffix
       --, sp_vpm.institutional_suffix                                                                as spouse_institutional_suffix
       , vpm.degrees
       --, sp_vpm.degrees                                                                             as spouse_degrees
       , vpm.pref_class_year
       --, sp_vpm.pref_class_year                                                                     as spouse_pref_class_year
       , vpm.addr_type
       , vpm.company_name_1
       , vpm.street1
       , vpm.street2
       , vpm.street3
       , vpm.city
       , vpm.state_code
       , vpm.zipcode
       , vpm.country
       , email_1."Email 1"
       , email_1."Email 1 Type"
       , email_2."Email 2"
       , email_2."Email 2 Type"
       , phone_1."Phone 1"
       , phone_1."Phone 1 Type"
       , phone_2."Phone 2"
       , phone_2."Phone 2 Type"
       , phone_3."Phone 3"
       , phone_3."Phone 3 Type"
       , vpm.trustee_flag
       , vpm.spouse_of_trustee_flag
       , vpm.handling_list
       , vpm.opt_out_list
       --, sp_vpm.handling_list                                                                       as spouse_handling_list
       --, sp_vpm.opt_out_list                                                                        as spouse_opt_out_list
       , vpm.anonymous_donor_ind
       , vpm.opt_in_only_flag
       , vpm.opt_in_list
       , vpm."ACTIVE_WITH_RESTRICTIONS_(AWR)"
       , vpm.awr_groups
       --, sp_vpm."ACTIVE_WITH_RESTRICTIONS_(AWR)"                                                    as spouse_active_with_restrict
       --, sp_vpm.awr_groups                                                                          as spouse_awr_groups
       , vpm.pref_name_sort
       , MGR.REPORT_NAME                                                                            AS "Prospect_Manager"
           
       , gift_info.ALLOC_CODE1 || ' - ' || GIFT_INFO.ALLOCATION1 AS "Allocation"
       , mr_gift_date.date_of_record                                                                as "Gift Date"
       , gift_info.GIFT_CREDIT1                                                                     as "Gift Amount"
 from    hh_list
     join    advance_nu_rpt.v_postal_list_template vpm
       on    (vpm.id_number = hh_list."ID Number")
     join    entity e
       on    (e.id_number = hh_list."ID Number")
left join    advance_nu_rpt.v_postal_list_template sp_vpm
       on    (e.spouse_id_number = sp_vpm.id_number
      and    e.jnt_mailings_ind = 'Y'
      and    e.jnt_gifts_ind = 'Y'
      and    sp_vpm.id_number not in (select id_number from restrictions))
left join    mr_gift_date
       on    (mr_gift_date.id_number = vpm.id_number)
left join    gift_info
       on    (gift_info.id_number = vpm.id_number)
left join    email_1
       on    (email_1."ID Number" = vpm.id_number)
left join    email_2
       on    (email_2."ID Number" = vpm.id_number)
left join    phone_1
       on    (phone_1."ID Number" = vpm.id_number)
left join    phone_2
       on    (phone_2."ID Number" = vpm.id_number)
left join    phone_3
       on    (phone_3."ID Number" = vpm.id_number)
LEFT OUTER JOIN PROSPECT_ENTITY PE ON vpm.ID_NUMBER = PE.ID_NUMBER
LEFT OUTER JOIN PROSPECT P ON PE.PROSPECT_ID = P.PROSPECT_ID
LEFT OUTER JOIN ASSIGNMENT A ON A.PROSPECT_ID = P.PROSPECT_ID AND A.ACTIVE_IND = 'Y' AND A.ASSIGNMENT_TYPE = 'PM'
LEFT OUTER JOIN ENTITY MGR ON A.ASSIGNMENT_ID_NUMBER = MGR.ID_NUMBER
LEFT OUTER JOIN MBTI_INVITE_MASTER_LIST M ON CASE WHEN E.LAST_NAME = '' THEN VPM.pref_mail_name ELSE e.last_name END = CASE WHEN M."Last Name" IS NULL THEN M."Name" ELSE M."Last Name" END AND SUBSTR(vpm.zipcode,1,5) = SUBSTR(M."Zip Code",1,5) 
LEFT OUTER JOIN f_alloc f on hh_list."ID Number" = f."ID Number"
;
