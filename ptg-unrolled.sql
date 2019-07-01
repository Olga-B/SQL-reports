select activity.foname orgcode
, signups.vanid
, signups.eventsignupid
, sched.schedstatusdate
, events.dateoffsetbegin::date
, fo.turf_type
, roles.eventrolename
, status.eventstatusname
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
where sched.schedstatusdate < events.dateoffsetbegin::date and date_trunc('week',sched.schedstatusdate) = date_trunc('week',(current_date - interval '1 day'))
                and date_trunc('week',(events.dateoffsetbegin::date)) >= date_trunc('week',(current_date - interval '1 day'))
                and date_trunc('week',(events.dateoffsetbegin::date)) <= date_trunc('week',(current_date + interval '13 days'))
--group by 1,15
order by 1
