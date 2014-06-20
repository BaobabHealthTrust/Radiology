
start_time = Time.now()
puts "Start Time: #{start_time.strftime('%Y-%m-%d %H:%M:%S')}"
logger = Logger.new(Rails.root.join("log",'convert_concepts.log'))
logger.info "Start Time: #{start_time.strftime('%Y-%m-%d %H:%M:%S')}"
###############################################
#move US from Abdomen to Abdomen US
=begin
order_type_id = OrderType.find_by_name("RADIOLOGY").order_type_id
ultrasound_order_concept_id = ConceptName.find_by_name("ULTRASOUND").concept_id
radiology_examination_encounter_id = EncounterType.find_by_name("RADIOLOGY EXAMINATION").encounter_type_id
examination_concept_id = ConceptName.find_by_name("EXAMINATION").concept_id

obs = Observation.find_by_sql("SELECT o.* FROM obs o
                                     INNER JOIN encounter e
                                     ON o.encounter_id = e.encounter_id
                                     INNER JOIN orders od
                                     ON od.encounter_id = o.encounter_id
                                     WHERE od.voided = 0
                                     AND od.concept_id = #{ultrasound_order_concept_id}
                                     AND od.order_type_id = #{order_type_id}
                                     AND e.encounter_type = #{radiology_examination_encounter_id}
                                     AND o.concept_id = #{examination_concept_id}
                                     AND o.value_coded = 8400")


obs.each do |ob|
 ob.value_coded = 9377
 ob.value_coded_name_id = 12572
 s = ob.save!
 puts s.inspect
end
#####################################################
=end
###############################################
#Make prostate gland detailed exam for Male Pelvis
order_type_id = OrderType.find_by_name("RADIOLOGY").order_type_id
ultrasound_order_concept_id = ConceptName.find_by_name("ULTRASOUND").concept_id
radiology_examination_encounter_id = EncounterType.find_by_name("RADIOLOGY EXAMINATION").encounter_type_id
examination_concept_id = ConceptName.find_by_name("EXAMINATION").concept_id
prostate_concept_id = ConceptName.find_by_name("PROSTATE GLAND").concept_id
detailed_examination_concept_id = ConceptName.find_by_name("DETAILED EXAMINATION").concept_id
male_pelvis_concept = ConceptName.find_by_name("MALE PELVIS")

obs = Observation.find_by_sql("SELECT o.* FROM obs o
                                     INNER JOIN encounter e
                                     ON o.encounter_id = e.encounter_id
                                     INNER JOIN orders od
                                     ON od.encounter_id = o.encounter_id
                                     WHERE od.voided = 0
                                     AND od.concept_id = #{ultrasound_order_concept_id}
                                     AND od.order_type_id = #{order_type_id}
                                     AND e.encounter_type = #{radiology_examination_encounter_id}
                                     AND o.concept_id = #{examination_concept_id}
                                     AND o.value_coded =  #{prostate_concept_id}")


obs.each do |ob|

pelvis_obs = Observation.new
pelvis_obs.person_id = ob.person_id
pelvis_obs.concept_id = examination_concept_id
pelvis_obs.encounter_id = ob.encounter_id 
pelvis_obs.obs_datetime = ob.obs_datetime 
pelvis_obs.value_coded = male_pelvis_concept.concept_id 
pelvis_obs.value_coded_name_id =  male_pelvis_concept.concept_name_id
pelvis_obs.creator = ob.creator
p = pelvis_obs.save!
puts p.inspect
 ob.concept_id = detailed_examination_concept_id
 s = ob.save!
 puts s.inspect
end
#####################################################

end_time = Time.now()
logger.info "End Time : #{end_time.strftime('%Y-%m-%d %H:%M:%S')}"
puts "End Time : #{end_time.strftime('%Y-%m-%d %H:%M:%S')}\n\n"
logger.info "Completed successfully !!"
