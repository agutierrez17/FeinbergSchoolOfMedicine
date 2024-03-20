--------------------------------------------------------------------------------------------------------------------------------------
/*	Request Details
--------------------------------------------------------------------------------------------------------------------------------------
	Requestor:                          Kirsten Byers						
	Email:							    kirsten-byers@northwestern.edu
	NetID:							    keb456
	Team Name:                          FSM Alumni Relations
	Due Date:                           11/17/2023
	Title:                              FSM CYE Mailing
	Purpose:                            Calendar Year End Mailing and Email
	Reviewers:                          Kirsten Byers
	Save Location:                      Feinberg L Drive - FSM Annual Giving       
	Rerun ID:                           FP 1342835
    Changes:                            Add in FSM Lifetime Giving
	Contact Entities:                   Yes
	Solicitation:                       Yes
	Invitation:                         No 
	Survey:                             No
	Contact Method:                     Email, Postal Mail
	Encompass Category:                 FSM Annual Giving
	Send Message As:                    FSM
	Include Certificates:               No
	Entity Output:                      Email: One row per entity, Postal: One row per household
	Include Orgs:                       No                   
	Include Students:                   No
	Trustees:                           No
	Criteria:                           Please include all FSM Alumni (MD. GME, PT(DPT, MPT, certificate)and PA) and please break them 
                                        out by alumni group.
	Columns:                            Standard output plus:
                                            Last gift Amount
                                            Last Gift Allocation
                                            Last Gift Lockbox Code
                                            Founders Society Flag
                                            FSM Lifetime Giving
                                            Active Pledge Flag

--------------------------------------------------------------------------------------------------------------------------------------
	Notes
--------------------------------------------------------------------------------------------------------------------------------------
    Find all code descriptions in corresponding tms tables in Advance (e.g. school_code description for 'MED' is in tms_schools, and 
    description from degree_code is in tms_degrees, etc.)


--------------------------------------------------------------------------------------------------------------------------------------
    Population Selection */
--------------------------------------------------------------------------------------------------------------------------------------

	 with    f_degree 					as 
(--Anyone that completed a degree from Feinberg
   select    distinct(d.id_number)
     from    degrees d
    where    d.school_code = 'MED'                                                                      --Feinberg
	  and    d.institution_code = '31173'                                                               --Northwestern
	  and    d.non_grad_code = ' '                                                                      --NOT a non-grad
)

		   , md 						as 
(--Anyone that compelted an MD degree from Feinberg
   select    distinct(d.id_number)
	 from    degrees d
	where    d.school_code = 'MED'
	  and    d.institution_code = '31173'
	  and    d.non_grad_code = ' '
	  and    d.degree_code = 'MD'                                                                       --MD degree
)

		   , pt 						as 
(--Anyone that compelted a Physical Therapy degree from Feinberg
   select    distinct d.id_number
	 from    degrees d
	where    d.school_code = 'MED'
	  and    d.institution_code = '31173'
	  and    d.non_grad_code = ' '
	  and    (d.dept_code = '16DPT'                                                                     --Physical Therapy department
	   or    d.degree_code in ('DPT', 'BSPT', 'MPT', 'PTR'))                                            --All Physical Therapy degrees                                                                                                                                                                                                                
)

		   , gme 						as 
(--Anyone that compelted a GME degree from Feinberg
   select    distinct(d.id_number)
	 from    degrees d
	where    d.school_code = 'MED'
	  and    d.institution_code = '31173'
	  and    d.degree_code in ('GMEF', 'GMER')                                                          --GME Fellowship/Residency
	  and    d.non_grad_code = ' '
)

		   , other_fsm 					as 
(--Any other degree type not previously listed
   select    distinct(d.id_number)
	 from    degrees d
	where    d.school_code = 'MED'
	  and    d.institution_code = '31173'
	  and    d.degree_code not in ('GMEF', 'GMER', 'MD', 'DPT', 'BSPT', 'MPT', 'PTR')
	  and    d.dept_code <> '16DPT'
	  and    d.non_grad_code = ' '
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

   --exclude Do Not Solicit, No Contact, Never Engaged, No Email, No Email Solicitation
   select    id_number
	 from    handling h
	where    h.hnd_status_code = 'A'
	  and    h.hnd_type_code in ('DNS', 'NC', 'NDR', 'NED', 'NE', 'NES') 
	union 

   --exclude All Communication, All Solicitation, Email Communication, Email Solicitation, Feinberg Alumni Annual Giving, No Alumni Communication
   select    id_number
	 from    mailing_list ml
	where    ml.mail_list_status_code = 'A'
	  and    ml.unit_code in (' ', 'FS', 'FSAG', 'FSAR')                                                /*Unit code defines how to apply the mail list code 
                                                                                                        (e.g. I want to be excluded from All Communication from Feinberg (FS))*/
	  and    ml.mail_list_code in ('AC', 'AS', 'EC', 'ES', 'ENF10', 'NAC') 
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
	  and    ml.mail_list_code in ('AC', 'AS', 'EC', 'ES', 'ENF10', 'NAC') 
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
   select    id_number 
	 from    f_degree
	minus
   select    id_number
	 from    restrictions
)
--------------------------------------------------------------------------------------------------------------------------------------
/*	Additional Columns */
--------------------------------------------------------------------------------------------------------------------------------------
		   , mr_gift_date 				as
(  --identify the most recent gift date to Feinberg
   select    g.gift_donor_id 																			as id_number
		   , max(g.gift_date_of_record) 																as date_of_record
	 from    gift g
	where    g.gift_donor_id in (select id_number from all_ids)                                         --only include contactable for this mailing
	  and    g.gift_alloc_school = 'FS'
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

		   , gift_info 					as 
(--for gifts with multiple allocations, show details for up to three allocations
   select    id_number
		   , max(decode(rnk,1,allocation_code)) 														as alloc_code1
		   , max(decode(rnk,1,allocation)) 																as allocation1
		   , max(decode(rnk,1,lock_box)) 																as lock_box1
		   , max(decode(rnk,1,gift_credit_amount)) 														as gift_credit1
		   , max(decode(rnk,2,allocation_code)) 														as alloc_code2
		   , max(decode(rnk,2,allocation)) 																as allocation2
		   , max(decode(rnk,2,lock_box)) 																as lock_box2
		   , max(decode(rnk,2,gift_credit_amount)) 														as gift_credit2
		   , max(decode(rnk,3,allocation_code)) 														as alloc_code3
		   , max(decode(rnk,3,allocation)) 																as allocation3
		   , max(decode(rnk,3,lock_box)) 																as lock_box3
		   , max(decode(rnk,3,gift_credit_amount)) 														as gift_credit3
	 from    mr_gift_alloc
 group by    id_number
)

		   , founders_soc 				as 
(  --Active Founders Society Gift Club
   select    gc.gift_club_id_number             														as id_number
     from    gift_clubs gc 
    where    gc.gift_club_code = 'LFS'                                                                  --Founders Society Member
      and    gc.gift_club_status = 'A'
)

		   , active_pledge 				as 
(--Active pledge
   select    distinct(p.pledge_donor_id) 																as id_number
	 from    pledge p
	 join    primary_pledge pp
	   on    pp.prim_pledge_number = p.pledge_pledge_number
	  and    pp.prim_pledge_status = 'A'
)

		   , fsm_lftm_gvng 				as 
(--Lifetime giving to Feinberg
   select    entity_key id_number
           , lifetime_gift_credit_amount
	 from    dm_ard.fact_donor_summary@catrackstobi fds 
	where    reporting_area = 'FS'
	  and    annual_fund_flag = 'N'
)
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*  Report Output */
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

   select    elt.*                                                                                      --all fields from email list template
		   , case 
		   		when md.id_number is not null 
				then 'Y' 
				else ' ' 
			  end 																						as md 
		   , case 
		   		when gme.id_number is not null 
		   		then 'Y' 
				else ' ' 
			  end 																						as gme 
		   , case 
		   		when pt.id_number is not null 
				then 'Y' 
				else ' ' 
			  end 																						as pt 
		   , case 
		   		when other_fsm.id_number is not null 
				then 'Y' 
				else ' ' 
			  end 																						as other_fsm
		   , case 
		   		when fs.id_number is not null 
				then 'Y' 
				else ' ' 
			  end 																						as founders_flag 
		   , case 
		   		when ap.id_number is not null 
				then 'Y' 
				else ' ' 
			  end 																						as active_pledge_flag
		   , mr_gift_date.date_of_record 																as mr_gift_date
		   , gift_info.*
		   , flg.lifetime_gift_credit_amount 															as fsm_lifetime_giving
	 from    advance_nu_rpt.v_email_list_template elt
	 join    all_ids
	   on    (all_ids.id_number = elt.id_number)
left join    mr_gift_date
	   on    (mr_gift_date.id_number = all_ids.id_number)
left join    gift_info
	   on    (gift_info.id_number = all_ids.id_number)
left join    md
	   on    (md.id_number = all_ids.id_number)
left join    pt
	   on    (pt.id_number = all_ids.id_number)
left join    gme
	   on    (gme.id_number = all_ids.id_number)
left join    other_fsm
	   on    (other_fsm.id_number = all_ids.id_number)
left join    founders_soc fs
	   on    (fs.id_number = all_ids.id_number) 
left join    active_pledge ap 
	   on    (ap.id_number = all_ids.id_number)
left join    fsm_lftm_gvng flg 
	   on    (flg.id_number = all_ids.id_number)
;
