select activity.foname orgcode
, count(distinct case when status.eventstatusname in ('Conf Twice', 'Confirmed','Left Msg','Scheduled','Sched-Web','Invited') 
				and events.dateoffsetbegin::date < current_date 
				then signups.eventsignupid else null end) open_shifts
, count(distinct case when volrec.datecanvassed < current_date then volrec.contactscontactid else null end) volreccallstw
, count(distinct case when volrec.datecanvassed::date = (current_date - interval '1 day') 
				and '%'||volrec.ufirst||'%' ilike '%'||fo.first||'%'
				and '%'||volrec.ulast||'%' ilike '%'||fo.last||'%' 
				then volrec.contactscontactid else null end) focallsyday
, count(distinct case when sched.schedstatusdate is not null and sched.schedstatusdate < events.dateoffsetbegin::date
                and date_trunc('week',sched.schedstatusdate) = date_trunc('week',(current_date - interval '1 day'))
                and date_trunc('week',(events.dateoffsetbegin::date)) >= date_trunc('week',(current_date - interval '1 day'))
                and date_trunc('week',(events.dateoffsetbegin::date)) <= date_trunc('week',(current_date + interval '13 days'))         
              	--and status.eventstatusname in ('Conf Twice', 'Confirmed','Left Msg','Scheduled')
                and fo.turf_type = 'DVC' 
                and roles.eventrolename in ('Canvasser', 'Phonebanker','MyV Phone Banker','MyC Phone Banker','Dialer')
                then signups.eventsignupid else null end) "Action Shifts recruited this week through the Next 2 Weeks in DVC turf - no magic"
, count(distinct case when sched.schedstatusdate = (current_date - interval '1 day') 
				and sched.schedstatusdate < events.dateoffsetbegin::date
                and date_trunc('week',(events.dateoffsetbegin::date)) >= date_trunc('week',(current_date - interval '1 day'))
                and date_trunc('week',(events.dateoffsetbegin::date)) <= date_trunc('week',(current_date + interval '13 days'))         
              	--and status.eventstatusname in ('Conf Twice', 'Confirmed','Left Msg','Scheduled')
                and fo.turf_type = 'DVC' 
                and roles.eventrolename in ('Canvasser', 'Phonebanker','MyV Phone Banker','MyC Phone Banker','Dialer')
                then signups.eventsignupid else null end) "Action Shifts recruited yday through the Next 2 Weeks in DVC turf - no magic"
, count(distinct case when sched.schedstatusdate is not null and sched.schedstatusdate < events.dateoffsetbegin::date
                and date_trunc('week',sched.schedstatusdate) = date_trunc('week',(current_date - interval '1 day'))
                and date_trunc('week',(events.dateoffsetbegin::date)) >= date_trunc('week',(current_date - interval '1 day'))
                and date_trunc('week',(events.dateoffsetbegin::date)) <= date_trunc('week',(current_date + interval '13 days'))         
              	--and status.eventstatusname in ('Conf Twice', 'Confirmed','Left Msg','Scheduled')
                and fo.turf_type = 'CO'
                then signups.eventsignupid else null end) "Attendee Shifts recruited this week through the Next 2 Weeks in CO turf - no magic"				
, count(distinct case when sched.schedstatusdate = (current_date - interval '1 day') 
				and sched.schedstatusdate < events.dateoffsetbegin::date
                and date_trunc('week',sched.schedstatusdate) = date_trunc('week',(current_date - interval '1 day'))
                and date_trunc('week',(events.dateoffsetbegin::date)) >= date_trunc('week',(current_date - interval '1 day'))
                and date_trunc('week',(events.dateoffsetbegin::date)) <= date_trunc('week',(current_date + interval '13 days'))         
              	--and status.eventstatusname in ('Conf Twice', 'Confirmed','Left Msg','Scheduled')
                and fo.turf_type = 'CO'
                then signups.eventsignupid else null end) "Attendee Shifts recruited yday through the Next 2 Weeks in CO turf - no magic"
, count(distinct case when teams.co_confirmed is null 
				and teams.dvc_confirmed is null 
				and teams.fall is null 
				and everactives.completed_as28 >1
				then signups.vanid else null end) SAV                
, count(distinct case when teams.co_confirmed is null 
				and teams.dvc_confirmed is null 
				and teams.fall is null 
				and everactives.completed_as28 = 1
                and status.eventstatusname in ('Conf Twice', 'Confirmed','Left Msg','Scheduled')
                and roles.eventrolename in ('Canvasser', 'Phonebanker','MyV Phone Banker','MyC Phone Banker','Dialer')  
				and date_trunc('week',events.dateoffsetbegin::date) = date_trunc('week',(current_date - interval '1 day'))  
				then signups.vanid else null end) NSA                
, count(distinct case when teams.co_confirmed is null 
				and teams.dvc_confirmed is null 
				and teams.fall is null 
				and everactives.completed_as28 > 1
				and everactives.completed_as28 - everactives.completed_as_riskweek < 2
				and (status.eventstatusname in ('Conf Twice', 'Confirmed','Left Msg','Scheduled') 
					and date_trunc('week',events.dateoffsetbegin::date) != date_trunc('week',(current_date - interval '1 day')))
				then signups.vanid else null end) AtRisk
, count(distinct case when fo.turf_type = 'CO' 
					and teams.co_confirmed is not null 
						then teams.vanid
					when fo.turf_type  = 'DVC'
					and teams.dvc_confirmed is not null
						then teams.vanid
					else null end ) confirmedteam
, count(distinct case when fo.turf_type = 'CO' 
					and teams.co_prospect is not null 
						then teams.vanid
					when fo.turf_type  = 'DVC'
					and teams.dvc_prospect is not null
						then teams.vanid
					else null end ) prospectteam
, count(distinct case when fo.turf_type = 'CO' 
					and teams.co_test is not null 
						then teams.vanid
					when fo.turf_type  = 'DVC'
					and teams.dvc_test is not null
						then teams.vanid
					else null end ) testteam	
, nvl(fo."last",'dne')||', '||nvl(fo."first" ,'dne') organizer
, count(distinct case when sched.schedstatusdate is not null and sched.schedstatusdate < events.dateoffsetbegin::date
                --and date_trunc('week',sched.schedstatusdate) = date_trunc('week',(current_date - interval '1 day'))
                and date_trunc('week',(events.dateoffsetbegin::date)) >= date_trunc('week',(current_date - interval '1 day'))
                and date_trunc('week',(events.dateoffsetbegin::date)) <= date_trunc('week',(current_date + interval '13 days'))         
              	and status.eventstatusname in ('Conf Twice', 'Confirmed','Left Msg','Scheduled')
                and ((fo.turf_type = 'DVC' and roles.eventrolename in ('Canvasser', 'Phonebanker','MyV Phone Banker','MyC Phone Banker','Dialer'))  or fo.turf_type = 'CO')
                then signups.eventsignupid else null end) "Action or Attendee Shifts scheduled for the Next 2 Weeks - no magic"
, count(distinct case when sched.schedstatusdate < events.dateoffsetbegin::date
                and date_trunc('week',sched.completedstatusdate) = date_trunc('week',(current_date - interval '1 day'))
                and date_trunc('week',(events.dateoffsetbegin::date)) = date_trunc('week',(current_date - interval '1 day'))                       
              	--and status.eventstatusname in ('Conf Twice', 'Confirmed','Left Msg','Scheduled')
                and ((fo.turf_type = 'DVC' and roles.eventrolename in ('Canvasser', 'Phonebanker','MyV Phone Banker','MyC Phone Banker','Dialer'))  or fo.turf_type = 'CO')
                then signups.eventsignupid else null end) "Action or Attendee Shifts Completed This Week - no magic"
, count(distinct case when teams.dvc_confirmed is null 
				and teams.co_confirmed is null
				and fall is null
				and everactives.completed_as28 = 1 
                and sched.schedstatusdate < events.dateoffsetbegin::date
                --and date_trunc('week',sched.schedstatusdate) = date_trunc('week',(current_date - interval '1 day'))
                and date_trunc('week',(events.dateoffsetbegin::date)) >= date_trunc('week',(current_date - interval '1 day'))
                and date_trunc('week',(events.dateoffsetbegin::date)) <= date_trunc('week',(current_date + interval '13 days'))       
                and status.eventstatusname in ('Conf Twice', 'Confirmed','Left Msg','Scheduled')
                and roles.eventrolename in ('Canvasser', 'Phonebanker','MyV Phone Banker','MyC Phone Banker','Dialer')  
                then signups.vanid else null end) "Actives Scheduled for Action Shifts in the Next Two Weeks" 
, count(distinct case when teams.dvc_confirmed is null 
				and teams.co_confirmed is null
				and fall is null
				and everactives.last_asdate <= (current_date - interval '29 days') 
                and sched.schedstatusdate < events.dateoffsetbegin::date
                --and date_trunc('week',sched.schedstatusdate) = date_trunc('week',(current_date - interval '1 day'))
                and date_trunc('week',(events.dateoffsetbegin::date)) >= date_trunc('week',(current_date - interval '1 day'))
                and date_trunc('week',(events.dateoffsetbegin::date)) <= date_trunc('week',(current_date + interval '13 days'))       
               	and status.eventstatusname in ('Conf Twice', 'Confirmed','Left Msg','Scheduled')
                and roles.eventrolename in ('Canvasser', 'Phonebanker','MyV Phone Banker','MyC Phone Banker','Dialer')  
                then signups.vanid else null end) "Dropped Scheduled  for Action Shifts in the Next Two Weeks" 
/*
,(select count(distinct p.votebuilder_identifier)
from vansync_il_gov_2018.analytics_person_il p
join civis.all_scores_general g
  on (exists (select * from civis.ts_dnc_crosswalk cw 
  where cw.personid = p.personid and cw.voterbase_id = g.voterbase_id ) and g.persuasion_van >=3.6 or g.gotv_van >= 3.75)
join vansync_il_gov_2018.dnc_contactscontacts_vf cc
    on cc.committeeid = 60225 
    and date_trunc('week',cc.datecanvassed) = date_trunc('week',(current_date - interval '1 day')) 
    and cc.contacttypeid = 2
    and cc.vanid = p.votebuilder_identifier
left join vansync_il_gov_2018.dnc_turf turf
on p.vanprecinctid = turf.precinctid where turf.foname = effective.foname) people_knocked
,(select count(distinct case when biz_support ilike '%confirm%' and biz_action is not null then vanid else null end) biz
from jb4gov.CTV_Biz_CB
where collected_orgcode = effective.foname) SB
,coalesce((select sum(minutes_logged_in)
    from jb4gov.ob_gsheet_hubdialer dialer
    where date_trunc('week',dialer.logged_in::date) = date_trunc('week',(current_date - interval '1 day'))
    and dialer.org_code ilike effective.foname),0) dialer_minutes
,(select count(distinct case when date_trunc('week',ctv_date) = date_trunc('week',(current_date - interval '1 day')) then vanid else null end) ctv
from jb4gov.CTV_Biz_CB
where collected_orgcode = effective.foname) CTV_tw
*/
from
vansync_il_gov_2018.dnc_activityregions activity
full outer join vansync_il_gov_2018.dnc_eventsignups signups on 
	activity.vanid = signups.vanid 
	and activity.statecode = signups.statecode
	and signups.datesuppressed is null 
	and signups.statecode = 'IL'
full outer join (select attempts.vanid 
				, attempts.contactscontactid
				, attempts.datecanvassed 
				, lower(dnc_users.lastname) ulast
				, lower(dnc_users.firstname) ufirst
			from vansync_il_gov_2018.dnc_contactscontacts_myc attempts
			join vansync_il_gov_2018.dnc_contacttypes ct on 
				attempts.contacttypeid = ct.contacttypeid 
				and ct.contacttypename = 'Phone'
				and attempts.datecanvassed >= date_trunc('week', (current_date - interval '1 day')) 
			join vansync_il_gov_2018.dnc_users on 
				dnc_users.userid = attempts.canvassedby 
				and dnc_users.statecode = attempts.statecode
				and attempts.statecode = 'IL' 
			/*where attempts.statecode = 'IL'
				and ct.contacttypename = 'Phone'
				and attempts.datecanvassed >= date_trunc('week', (current_date - interval '1 day'))*/ ) volrec on 
	activity.vanid  = volrec.vanid 
left join jb4gov.fo_code_pod_turf_type fo on 
	fo.org_code = activity.foname 
join vansync_il_gov_2018.dnc_eventsignupsstatuses currentstatus on 
	currentstatus.eventsignupseventstatusid = signups.currenteventsignupseventstatusid 
	and currentstatus.eventsignupid = signups.eventsignupid
	and currentstatus.statecode = signups.statecode
join vansync_il_gov_2018.dnc_eventstatuses status on 
	currentstatus.eventstatusid = status.eventstatusid
	--and status.eventstatusname in ('Conf Twice', 'Confirmed','Left Msg','Scheduled','Completed')
join vansync_il_gov_2018.dnc_events events on 
	(signups.eventid = events.eventid 
	and events.datesuppressed is null 
	and events.statecode = signups.statecode
	and events.dateoffsetbegin::date >= current_date-interval '100 days'
	and date_trunc('week',(events.dateoffsetbegin::date)) <= date_trunc('week',(current_date + interval '13 days'))
		)	    
join vansync_il_gov_2018.dnc_eventcalendars eventtype 
		on ( eventtype.eventcalendarid = events.eventcalendarid and eventtype.isactive = 1)
join vansync_il_gov_2018.dnc_eventroles roles 
		on (roles.eventroleid = signups.eventroleid and roles.datesuppressed is null)
left join (select eventsignupid
		        ,min(case when eventstatusname != 'Completed' then datecreated::date else null end) schedstatusdate
		        ,max(case when eventstatusname = 'Completed' then datecreated::date else null end) completedstatusdate
		        from vansync_il_gov_2018.dnc_eventsignupsstatuses
		        join vansync_il_gov_2018.dnc_eventstatuses on dnc_eventstatuses.eventstatusid = dnc_eventsignupsstatuses.eventstatusid 
		        and dnc_eventstatuses.eventstatusname in ('Conf Twice', 'Confirmed','Left Msg','Scheduled','Completed') and dnc_eventsignupsstatuses.statecode = 'IL' 
		        group by 1) sched		  
		on sched.eventsignupid = signups.eventsignupid
full outer join (select signupsav.vanid
				,count(distinct case when signupsav.datetimeoffsetbegin::date > (current_date - interval '29 days') then signupsav.eventsignupid else null end) completed_as28
				,count(distinct case when signupsav.datetimeoffsetbegin::date > (current_date - interval '29 days') 
					and signupsav.datetimeoffsetbegin::date < (current_date - interval '21 days')
					then signupsav.eventsignupid else null end) completed_as_riskweek
				,max(signupsav.datetimeoffsetbegin::date ) last_asdate
				from vansync_il_gov_2018.dnc_eventsignups signupsav
				join vansync_il_gov_2018.dnc_eventroles roles on roles.eventroleid = signupsav.eventroleid and roles.eventrolename in ('Canvasser', 'Phonebanker','MyV Phone Banker','MyC Phone Banker','Dialer')
				join vansync_il_gov_2018.dnc_eventstatuses status on 
					(exists(select * from vansync_il_gov_2018.dnc_eventsignupsstatuses cw 
				where cw.eventsignupid = signupsav.eventsignupid 
					and cw.statecode = signupsav.statecode 
					and cw.eventsignupseventstatusid = signupsav.currenteventsignupseventstatusid 
					and cw.eventstatusid = status.eventstatusid 
					and signupsav.datesuppressed is null 						
					and status.eventstatusname = 'Completed'))						
				group by 1) everactives on 
		everactives.vanid = signups.vanid
full outer join (select distinct csr.vanid
			--,questions.surveyquestionname
     		,listagg(case when questions.surveyquestionname ilike 'co %' and answers.surveyresponsename ilike '%confirm%' then answers.surveyresponsename else null end)
     			within group (order by csr.vanid, csr.datecanvassed, questions.surveyquestionname) 
     			over (partition by csr.vanid) co_confirmed
     		,listagg(case when questions.surveyquestionname ilike 'co %' and answers.surveyresponsename ilike '%test%' then answers.surveyresponsename else null end)
     			within group (order by csr.vanid, csr.datecanvassed, questions.surveyquestionname) 
     			over (partition by csr.vanid) co_test
     		,listagg(case when questions.surveyquestionname ilike 'co %' and answers.surveyresponsename ilike '%prospect%' then answers.surveyresponsename else null end)
     			within group (order by csr.vanid, csr.datecanvassed, questions.surveyquestionname) 
     			over (partition by csr.vanid) co_prospect
     		,listagg(case when questions.surveyquestionname ilike 'dvc %' and answers.surveyresponsename ilike '%confirm%' then answers.surveyresponsename else null end) 
     			within group (order by csr.vanid, csr.datecanvassed, questions.surveyquestionname) 
     			over (partition by csr.vanid) dvc_confirmed     			
     		,listagg(case when questions.surveyquestionname ilike 'dvc %' and answers.surveyresponsename ilike '%test%' then answers.surveyresponsename else null end)
     			within group (order by csr.vanid, csr.datecanvassed, questions.surveyquestionname) 
     			over (partition by csr.vanid) dvc_test
     		,listagg(case when questions.surveyquestionname ilike 'dvc %' and answers.surveyresponsename ilike '%prospect%' then answers.surveyresponsename else null end)
     			within group (order by csr.vanid, csr.datecanvassed, questions.surveyquestionname) 
     			over (partition by csr.vanid) dvc_prospect
     		,listagg(case when questions.surveyquestionname ilike '%fall fellow%' then answers.surveyresponsename else null end)      			
     			within group (order by csr.vanid, csr.datecanvassed, questions.surveyquestionname) 
     			over (partition by csr.vanid) fall
			from 
			(select * , row_number () over (partition by vanid, surveyquestionid
	                             order by datecanvassed desc) answer_order
	                             from vansync_il_gov_2018.dnc_contactssurveyresponses_myc) csr
		    join vansync_il_gov_2018.dnc_surveyquestions questions on 
				csr.surveyquestionid = questions.surveyquestionid 
				and csr.answer_order = 1
				and csr.committeeid = 60225
		    	and ((questions.surveyquestionname ilike 'dvc %'
		      		or questions.surveyquestionname ilike 'co %') 
		      	AND (surveyquestionname ilike '%captain%' or surveyquestionname ilike '%leader%'))
		     or questions.surveyquestionname ilike '%fall fellow%'		     
	        join vansync_il_gov_2018.dnc_surveyresponses answers
			    on csr.surveyquestionid = answers.surveyquestionid 
			    and csr.surveyresponseid = answers.surveyresponseid
			    and questions.surveyquestionid = answers.surveyquestionid 
			    and (answers.surveyresponsename ilike '%confirm%' or answers.surveyresponsename ilike '%accepted%' or answers.surveyresponsename ilike '%test%' or answers.surveyresponsename ilike '%prospect%')			
			    order by 1) teams on teams.vanid = activity.vanid
group by 1,15
order by 1
