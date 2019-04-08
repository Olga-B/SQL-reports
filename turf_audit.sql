select ptb.new_precinct_id , 
ptb.sl ,
'R'||trim(to_char(case when fo.region is null then ptb.region else fo.region end ,'00')) region,
ptb.org_code ,
ptb.county,
ptb.precinct,
ptb.ward ,
sl.sl_name_hq_cp||'_'||ptb.county||'_'||regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(lower(precinct),
	'city of chicago ','Ch')
	,'city of rockford ','Rock')
	,'cunningham ','Cunning')
	,'city of champaign ','CityC')
	,'city of danville ','Dan')
	,'city of bloomington ', 'Bloom')
	,'champaign','Champ')
	,'city of galesburg','Galesburg')
	||'_CD'||p.us_cong_district_latest "cty-pct-cd",
p.us_cong_district_latest cd,
ptb.gotv_owner,
count(distinct targets.vanid) as targets_people,
count(distinct case when targets.vanid is not null then p.primary_voting_address_id else null end) as targets_doors,
count(distinct case when contacttypename is not null then ccvf.vanid else null end) as people_attempted_0913,
p.state_senate_district_latest ss,
p.state_house_district_latest sh,
ptb.township ,
ptb.name||'-'||p.us_cong_district_latest||'-'||p.state_senate_district_latest||'-'||p.state_house_district_latest as uniquecombo
from
vansync_il_gov_2018.analytics_person_il p 
left join jb4gov.vil_universes targets on 
	p.votebuilder_identifier = targets.vanid and targets.list_name = 'JBGOTV 1006'
join jb4gov.precinct_turfbook ptb on 
	p.vanprecinctid = ptb.new_precinct_id 
left join jb4gov.fo_code_pod_turf_type fo on fo.org_code = ptb.org_code 
left join jb4gov.sl_master sl on sl.staging_location_map = ptb.sl 
left join vansync_il_gov_2018.dnc_contactscontacts_vf ccvf on ccvf.vanid= targets.vanid and ccvf.committeeid = 60225 and ccvf.datecanvassed::date >= '2018-09-13'
left join vansync_il_gov_2018.dnc_contacttypes on ccvf.contacttypeid = dnc_contacttypes.contacttypeid and dnc_contacttypes.contacttypename = 'Walk'
where
	p.is_current_reg=1 and 
	p.reg_voter_flag=1 and 
	p.is_merged=0 and 
	p.is_deceased=0 and
	p.state_code = 'IL'
group by 1,2,3,4,5,6,7,8,9,10,14,15,16,17;


;
/*Map Region ID	Precinct ID	Staging Location	SL Code	File Name / Map Region*/

select zm.map_region_id
,cutpeople.precinctid
,sl.sl_name_hq_cp sl_name_packetland
,ptb.sl sl_code
,zm.map_region_name 
,zt.map_turf_name 
,count(distinct z.map_turf_id ) cut_packets
,count(distinct z.vanid ) cut_people
,(select count(distinct targets.vanid) from jb4gov.vil_universe_compare targets 
	join jb4gov.person_corrected cw on targets.vanid = cw.vanid_vf 
	where targets.list_name in ('CD13 DCCC DR Universe','CD12 DCCC DR Universe')
	and cw.precinctid  = cutpeople.precinctid ) og_targets
from 
vansync_il_gov_2018.zzzz2 z 
join vansync_il_gov_2018.zzzz2_region zm on z.stork_job_run_id  = zm.stork_job_run_id 
	and z.map_region_id  = zm.map_region_id 
join vansync_il_gov_2018.zzzz2_turf zt on z.stork_job_run_id  = zt.stork_job_run_id 
	and z.map_turf_id = zt.map_turf_id 
	and zt.map_region_id  = zm.map_region_id 
left join jb4gov.person_corrected cutpeople on z.vanid  = cutpeople.vanid_vf 
left join jb4gov.precinct_turfbook ptb on ptb.new_precinct_id  = cutpeople.precinctid 
left join jb4gov.sl_master sl on sl.staging_location_map  = ptb.sl
where zm.stork_job_run_id 
group by 1,2,3,4,5,6
;
select distinct map_region_id, map_region_name
from jb4gov.cd006_region_meta_yday 
union all jb4gov.cd006_region_metadata 
union all jb4gov.cutturf1014_region_metadata 
union all jb4gov.cutturf_region_metadata 
union all jb4gov.drcut1014_region_metadata 
union all jb4gov.drcut1016_region_metadata 
union all jb4gov.missedgotvfolders_region_metadata 
union all jb4gov.r10_stchar_region_metadata 
union all jb4gov.gotv1014_region_metadata 
union all jb4gov.gotv1016_region_metadata 
union all jb4gov.region_metadata 