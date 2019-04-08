select 
ptb.Name
,ptb.County
,ptb.Precinct
,ptb.Township
,ptb.Ward
,ptb.new_precinct_id
,p.us_cong_district_latest cd
,cd.democrat cd_targeted
,p.state_senate_district_latest ss
,ss.democrat ss_targeted
,ptb.Average_GOTV
,ptb.Walkabilty
,ptb.HH
,count(distinct case when universe.list_name = 'JBGOTV 1006' then universe.vanid else null end) JB_voters_people
,count(distinct p.votebuilder_identifier ) all_voters_people
,count(distinct p.primary_voting_address_id ) all_voters_doors
,ptb.precinct_type 
,ptb.owned_by_canvass_93
,ptb.owned_by_canvass_gotv 
,ptb.sl 
,count(distinct case when universe.list_name = 'JBGOTV 1006' then p.primary_voting_address_id else null end) JB_targets_doors
,count(distinct case 
				when universe.list_name = 'CD06 Universe 1006' and p.us_cong_district_latest = '006' then p.primary_voting_address_id
				when universe.list_name = 'CD12 GOTV Universe 1006' and p.us_cong_district_latest = '012' then p.primary_voting_address_id
				when universe.list_name = 'CD13 Universe 1006' and p.us_cong_district_latest = '013' then p.primary_voting_address_id
				when universe.list_name = 'CD14 Universe 1006' and p.us_cong_district_latest = '014' then p.primary_voting_address_id
			else null end) cd_targets_doors
,count(distinct case when universe.list_name = 'Senate 1s and 2s 1006' then p.primary_voting_address_id else null end) ss_targets_doors
FROM vansync_il_gov_2018.analytics_person_il p left join jb4gov.vil_universe_compare universe on p.votebuilder_identifier = universe.vanid and p.state_code = 'IL'
join jb4gov.precinct_label_tracker ptb on p.vanprecinctid = ptb.new_precinct_id
left join jb4gov.ob_races_targets cd on cd.name = p.us_cong_district_latest and cd.seat_type ='CD' and lower(cd.targeted_mm)='yes' 
left join jb4gov.ob_races_targets ss on SS.name = p.state_senate_district_latest and SS.seat_type ='SS' and lower(SS.targeted_mm)='yes' 
where 
  	p.is_current_reg=1 and 
	p.reg_voter_flag=1 and 
	p.is_merged=0 and 
	p.is_deceased=0
group by
ptb.Name
,ptb.County
,ptb.Precinct
,ptb.Township
,ptb.Ward
,ptb.new_precinct_id
,p.us_cong_district_latest 
,cd.democrat 
,p.state_senate_district_latest 
,ss.democrat
,ptb.Average_GOTV
,ptb.Walkabilty
,ptb.HH
--,count(distinct case when universe.list_name = 'JBGOTV 1006' then universe.vanid else null end) JB_voters_people
--,count(distinct p.votebuilder_identifier ) all_voters_people
--,count(distinct p.primary_voting_address_id ) all_voters_doors
,ptb.precinct_type 
,ptb.owned_by_canvass_93
,ptb.owned_by_canvass_gotv 
,ptb.sl 
order by 1
--,count(distinct case when universe.list_name = 'JBGOTV 1006' then p.primary_voting_address_id else null end) JB_voters_doors
