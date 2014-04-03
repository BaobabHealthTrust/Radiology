print "\e[H\e[2J"
puts "Start Time: #{Time.now}\n\n"

failure = File.open("failure_id.DAT", 'w')

puts "00.00%  [#{'-'*100}]"

obs=Observation.find(:all,
                     :conditions => ["concept_id IN (?) AND value_text IS NOT NULL",
                                     [8509]])

total=Hash.new(0)
progress = obs.length

obs.each_with_index do |o, i|
	#progress bar counter	
	move = (i.to_f/progress).round(2)*100 rescue 0
	
	value_text = o.value_text.to_s.strip
	test_value = value_text.upcase
	
	if ["UNKNOWN", "DO NOT KNOW", "DON'T KNOW"].include?(test_value)
		value_text = 1067

	elsif  ["NO", "NONO"].include?(test_value)
		value_text = 1066

	elsif 'YES' == test_value
		value_text = 1065

	end
	
	o.value_coded = value_text.to_i
	
	if o.save
		total[value_text.to_i]+=1
	else
		total["failure"]+=1
		
		failure.puts o.obs_id
		puts o.obs_id
	end
	
	print "\r\r\r#{move}%  [#{'>'*(move) + '-'*(100-move)}]"
		
end
puts "\n\n"

total.each do |c, v|
	puts "#{c} => #{v}"
end

puts "\nEnd Time: #{Time.now}"
puts "Completed successfully !!\n\n"
