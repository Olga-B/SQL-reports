select pc.precinctid, 
precinct_turfbook.name,
precinct_turfbook.county,
precinct_turfbook.precinct,
pc.countyname||'-'||pc.precinctname||'-'||pc.jurisdictionname||'-'||pc.cd||'-'||pc.ss||'-'||pc.sh as uniquecombo,
pc.cd,
(select targeted_mm from jb4gov.ob_races_targets targeted where targeted.name = pc.cd and targeted.seat_type = 'CD' limit 1) as cd_targeted,
pc.ss,
(select targeted_mm from jb4gov.ob_races_targets targeted where targeted.name = pc.ss and targeted.seat_type = 'SS' limit 1) as ss_targeted,
pc.sh,
(select targeted_mm from jb4gov.ob_races_targets targeted where targeted.name = pc.sh and targeted.seat_type = 'SH' limit 1) as sh_targeted,
count(distinct targets.vanid) as targets_people,
count(distinct case when targets.vanid is not null then coalesce(pc.streetno,'-')||coalesce(pc.streetnohalf,'-')||coalesce(pc.streetprefix,'-')||coalesce(pc.streetname,'-')||coalesce(pc.streettype,'-')||coalesce(pc.streetsuffix,'-')||coalesce(pc.apttype,'-')||coalesce(pc.aptno,'-') else null end) as targets_doors,
count(distinct case when contacttypename is not null then ccvf.vanid else null end) as people_attempted_0913
from
jb4gov.person_corrected pc
left join jb4gov.vil_universes targets on targets.vanid = pc.vanid_vf and targets.list_name = 'UnPen - VBM Paper Chase - Tier 1'
join jb4gov.precinct_turfbook on pc.precinctid = precinct_turfbook.new_precinct_id
left join vansync_il_gov_2018.dnc_contactscontacts_vf ccvf on ccvf.vanid= targets.vanid and ccvf.committeeid = 60225 and ccvf.datecanvassed::date >= '2018-09-13'
left join vansync_il_gov_2018.dnc_contacttypes on ccvf.contacttypeid = dnc_contacttypes.contacttypeid and dnc_contacttypes.contacttypename = 'Phone'
group by pc.precinctid,precinct_turfbook.county, precinct_turfbook.name, precinct_turfbook.precinct, pc.countyname, pc.precinctname,pc.jurisdictionname,pc.cd,pc.ss,pc.sh
;

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
group by 1,2,3,4,5,6,7,8,9,10,14,15,16,17
;

select pc.precinctid, 
precinct_turfbook.name,
precinct_turfbook.county,
precinct_turfbook.precinct,
pc.countyname||'-'||pc.precinctname||'-'||pc.jurisdictionname||'-'||pc.cd||'-'||pc.ss||'-'||pc.sh as uniquecombo,
pc.countyname||'-'||pc.precinctname||'-'||pc.cd "cty-pct-cd",
pc.cd,
pc.ss,
pc.sh,
count(distinct targets.vanid) as targets_people,
count(distinct case when targets.vanid is not null then coalesce(pc.streetno,'-')||coalesce(pc.streetnohalf,'-')||coalesce(pc.streetprefix,'-')||coalesce(pc.streetname,'-')||coalesce(pc.streettype,'-')||coalesce(pc.streetsuffix,'-')||coalesce(pc.apttype,'-')||coalesce(pc.aptno,'-') else null end) as targets_doors,
count(distinct case when contacttypename is not null then ccvf.vanid else null end) as people_attempted_0913
from
jb4gov.person_corrected pc
left join jb4gov.vil_universes targets on targets.vanid = pc.vanid_vf and targets.list_name = 'UnPen - PGM Canvass'
join jb4gov.precinct_turfbook on pc.precinctid = precinct_turfbook.new_precinct_id and precinct_turfbook.gotv_owner = 'Field - DVC'
left join vansync_il_gov_2018.dnc_contactscontacts_vf ccvf on ccvf.vanid= targets.vanid and ccvf.committeeid = 60225 and ccvf.datecanvassed::date >= '2018-09-13'
left join vansync_il_gov_2018.dnc_contacttypes on ccvf.contacttypeid = dnc_contacttypes.contacttypeid and dnc_contacttypes.contacttypename = 'Walk'
group by pc.precinctid,precinct_turfbook.county, precinct_turfbook.name, precinct_turfbook.precinct, pc.countyname, pc.precinctname,pc.jurisdictionname,pc.cd,pc.ss,pc.sh;