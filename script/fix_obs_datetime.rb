start_time = Time.now
puts "Start Time: #{start_time}\n\n"

failure = File.open("failure_id.DAT", 'w')
total_saved = 0
total_failed = 0

radiology_examination_encounter = EncounterType.find_by_name("RADIOLOGY EXAMINATION").encounter_type_id
film_size_encounter = EncounterType.find_by_name("FILM").encounter_type_id
notes_encounter = EncounterType.find_by_name("NOTES").encounter_type_id

encounter = Encounter.find(:all,
                   :conditions => ["encounter_type IN (?)",
                                   [radiology_examination_encounter,
                                    film_size_encounter,
                                    notes_encounter]
                                  ]
                           )
 encounter.each do |enc|
   enc.observations.each do |ob|
     ob.obs_datetime = enc.encounter_datetime
    if ob.save
		    total_saved +=1
        puts "Total saved : #{total_saved}"
	  else
		    total_failed +=1
        failure.puts ob.obs_id
	  end
  end
 end
end_time = Time.now
puts "\nEnd Time: #{end_time}"
puts "Total saved: #{total_saved}"
puts "Total failed: #{total_failed}"
puts "It took : #{end_time - start_time}"
puts "Completed successfully !!\n\n"



