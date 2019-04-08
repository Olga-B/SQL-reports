 --paid canvass universe contacts by pass
 select 
            turf.list_name wardname
            , pct_tracker.precinct
            , pct_tracker.hh 
            --PEOPLE--
            , count(distinct case when contacttypecodes.description = 'Paid Walk' 
            		and ccvf.committeeid = 65766
            		and ccvf.datecanvassed::date >= pass.date_door_pass_1 
            		and ccvf.datecanvassed::date < (CASE WHEN pass.date_door_pass_2 is not null then pass.date_door_pass_2 else current_date end) 
            		then ccvf.vanid 
              		ELSE NULL END
              ) AS p1attempts_people  
            , count(distinct turf.vanid) p1universe_people
            , count(distinct case when contacttypecodes.description = 'Paid Walk' 
            		and ccvf.committeeid = 65766
            		and ccvf.datecanvassed::date >= (CASE WHEN pass.date_door_pass_2 is not null then pass.date_door_pass_2 else current_date end) 
            		and ccvf.datecanvassed::date < (CASE WHEN pass.date_door_pass_3 is not null then pass.date_door_pass_3 else current_date end) 
            		then ccvf.vanid 
              		ELSE NULL END
              ) AS p2attempts_people  
            , count(distinct case when resultcodes.resultshortname in ('Deceased','Moved','Inaccessible','No Such Address','Refused')
            		and ccvf.datecanvassed::date  >= pass.date_door_pass_1 
            		and ccvf.datecanvassed::date < (CASE WHEN pass.date_door_pass_2 is not null then pass.date_door_pass_2 else current_date end) 
            		then null 
            		when recent_survey.negid is not null
            		and recent_survey.sqnegdate >= pass.date_door_pass_1 
            		and recent_survey.sqnegdate < (CASE WHEN pass.date_door_pass_2 is not null then pass.date_door_pass_2 else current_date end) 
            		then null
              		ELSE turf.vanid END
              ) AS p2universe_people
            , count(distinct case when contacttypecodes.description = 'Paid Walk' 
            		and ccvf.committeeid = 65766
            		and ccvf.datecanvassed::date >= (CASE WHEN pass.date_door_pass_3 is not null then pass.date_door_pass_3 else current_date end) 
            		and ccvf.datecanvassed::date < current_date 
            		then p.primary_voting_address_id 
              		ELSE NULL END
              ) AS p3attempts_people  
              , count(distinct case when resultcodes.resultshortname in ('Deceased','Moved','Inaccessible','No Such Address','Refused')
            		and ccvf.datecanvassed::date  >= pass.date_door_pass_1 
            		and ccvf.datecanvassed::date < (CASE WHEN pass.date_door_pass_3 is not null then pass.date_door_pass_3 when pass.date_door_pass_2 is not null then pass.date_door_pass_2 else current_date end) 
            		then null 
            		when recent_survey.negid is not null
            		and recent_survey.sqnegdate >= pass.date_door_pass_1 
            		and recent_survey.sqnegdate < (CASE WHEN pass.date_door_pass_3 is not null then pass.date_door_pass_3 when pass.date_door_pass_2 is not null then pass.date_door_pass_2 else current_date end)  
            		then null
              		ELSE turf.vanid end
              ) AS p3universe_people  
            , count(distinct case when contacttypecodes.description = 'Paid Walk' 
            		and ccvf.committeeid = 65766
            		and ccvf.datecanvassed::date >= pass.date_door_pass_1 
            		and ccvf.datecanvassed::date < (CASE WHEN pass.date_door_pass_2 is not null then pass.date_door_pass_2 else current_date end) 
            		then p.primary_voting_address_id
              		ELSE NULL END
              ) AS p1attempts_doors  
            -- DOORS
            , count(distinct p.primary_voting_address_id ) p1universe_doors
            , count(distinct case when contacttypecodes.description = 'Paid Walk' 
            		and ccvf.committeeid = 65766
            		and ccvf.datecanvassed::date >= (CASE WHEN pass.date_door_pass_2 is not null then pass.date_door_pass_2 else current_date end) 
            		and ccvf.datecanvassed::date < (CASE WHEN pass.date_door_pass_3 is not null then pass.date_door_pass_3 else current_date end) 
            		then p.primary_voting_address_id 
              		ELSE NULL END
              ) AS p2attempts_doors  
            , count(distinct case when resultcodes.resultshortname in ('Deceased','Moved','Inaccessible','No Such Address','Refused')
            		and ccvf.datecanvassed::date  >= pass.date_door_pass_1 
            		and ccvf.datecanvassed::date < (CASE WHEN pass.date_door_pass_2 is not null then pass.date_door_pass_2 else current_date end) 
            		then null 
            		when recent_survey.negid is not null
            		and recent_survey.sqnegdate >= pass.date_door_pass_1 
            		and recent_survey.sqnegdate < (CASE WHEN pass.date_door_pass_2 is not null then pass.date_door_pass_2 else current_date end) 
            		then null
              		ELSE p.primary_voting_address_id END
              ) AS p2universe_doors 
            , count(distinct case when contacttypecodes.description = 'Paid Walk' 
            		and ccvf.committeeid = 65766
            		and ccvf.datecanvassed::date >= (CASE WHEN pass.date_door_pass_3 is not null then pass.date_door_pass_3 else current_date end) 
            		and ccvf.datecanvassed::date < current_date 
            		then p.primary_voting_address_id 
              		ELSE NULL END
              ) AS p3attempts_doors  
              , count(distinct case when resultcodes.resultshortname in ('Deceased','Moved','Inaccessible','No Such Address','Refused')
            		and ccvf.datecanvassed::date  >= pass.date_door_pass_1 
            		and ccvf.datecanvassed::date < (CASE WHEN pass.date_door_pass_3 is not null then pass.date_door_pass_3 when pass.date_door_pass_2 is not null then pass.date_door_pass_2 else current_date end) 
            		then null 
            		when recent_survey.negid is not null
            		and recent_survey.sqnegdate >= pass.date_door_pass_1 
            		and recent_survey.sqnegdate < (CASE WHEN pass.date_door_pass_3 is not null then pass.date_door_pass_3 when pass.date_door_pass_2 is not null then pass.date_door_pass_2 else current_date end)  
            		then null
              		ELSE p.primary_voting_address_id end
              ) AS p3universe_doors  
            from jb4gov.vil_paid_canvass_universes turf
            left join jb4gov.paid_canvass_passes pass on turf.list_name = pass.ward
            join vansync_il_gov_2018.analytics_person_il p on p.votebuilder_identifier = turf.vanid and p.is_current_reg=1 and p.reg_voter_flag=1 and p.is_merged=0 and p.is_deceased=0
            left join jb4gov.precinct_label_tracker pct_tracker on p.vanprecinctid = pct_tracker.new_precinct_id
            left join vansync_il_gov_2018.dnc_contactscontacts_vf ccvf on (turf.vanid = ccvf.vanid and ccvf.datecanvassed>='2018-06-02')
            left join vansync_il_gov_2018.contacttypecodes on (ccvf.contacttypeid = contacttypecodes.contacttypeid)
			left join vansync_il_gov_2018.dnc_results resultcodes on ccvf.resultid = resultcodes.resultid
            left join (Select csr.vanid
						 	,csr.datecanvassed::date sqnegdate
						    ,questions.surveyquestionname
						    ,regexp_substr((case when (answers.surveyresponsename = '%Does Not Support'  or  answers.surveyresponsename like '%Does%Support') then 4::text else answers.surveyresponsename end), '[\\d]') negid
						    ,row_number () over (partition by csr.vanid, questions.surveyquestionname
						                             order by csr.datecanvassed desc) answer_order
						     From vansync_il_gov_2018.dnc_contactssurveyresponses_vf csr
						     join vansync_il_gov_2018.dnc_surveyresponses answers
						     on csr.surveyquestionid = answers.surveyquestionid 
						     and csr.surveyresponseid = answers.surveyresponseid
						    join vansync_il_gov_2018.dnc_surveyquestions questions
						     on answers.surveyquestionid = questions.surveyquestionid 
						     where (questions.surveyquestionname  ilike '%jb%id%' 
						     and surveyquestionname not ilike '%primary%'
						     )		
						        ) recent_survey
			on (recent_survey.vanid = ccvf.vanid and recent_survey.answer_order = 1 and recent_survey.negid >=4 and sqnegdate>='2018-06-02')
           group by 1,2,3
           order by 1,2,3 
           ;


            
            --ID RESULTS TO EXCLUDE FROM UNIVERSE--
select * from (Select csr.vanid
 	,csr.datecanvassed::date
    ,questions.surveyquestionname
    ,regexp_substr((case when (answers.surveyresponsename = '%Does Not Support'  or  answers.surveyresponsename like '%Does%Support') then 4::text else answers.surveyresponsename end), '[\\d]') ID
    ,row_number () over (partition by csr.vanid, questions.surveyquestionname
                             order by csr.datecanvassed desc) answer_order
     From vansync_il_gov_2018.dnc_contactssurveyresponses_vf csr
     join vansync_il_gov_2018.dnc_surveyresponses answers
     on csr.surveyquestionid = answers.surveyquestionid 
     and csr.surveyresponseid = answers.surveyresponseid
    join vansync_il_gov_2018.dnc_surveyquestions questions
     on answers.surveyquestionid = questions.surveyquestionid 
     where (questions.surveyquestionname  ilike '%jb%id%' 
     and surveyquestionname not ilike '%primary%'
     )		
        ) recent_survey
where recent_survey.answer_order = 1 and recent_survey.id >=4
;
select count(distinct list_name) from jb4gov.vil_paid_canvass_universes 
;
select regexp_substr(4::text,'[\\d]');
select *
From vansync_il_gov_2018.dnc_contactssurveyresponses_vf csr
     join vansync_il_gov_2018.dnc_surveyresponses answers
     on csr.surveyquestionid = answers.surveyquestionid 
     and csr.surveyresponseid = answers.surveyresponseid
    join vansync_il_gov_2018.dnc_surveyquestions questions
     on answers.surveyquestionid = questions.surveyquestionid 
where (questions.surveyquestionname  ilike '%jbgeneralid%' 
     --and surveyquestionname not ilike '%primary%'
     )		;
select * from vansync_il_gov_2018.dnc_results;