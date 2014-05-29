module Report
    def self.generate_cohort_date_range(quarter = "", start_date = nil, end_date = nil)

    quarter_beginning   = start_date.to_date  rescue nil
    quarter_ending      = end_date.to_date    rescue nil
    quarter_end_dates   = []
    quarter_start_dates = []
    date_range          = [nil, nil]

    if(!quarter_beginning.nil? && !quarter_ending.nil?)
      date_range = [quarter_beginning, quarter_ending]
		elsif (!quarter.nil? && quarter == "Cumulative")
      quarter_beginning = PatientService.initial_encounter.encounter_datetime.to_date rescue Date.today
      quarter_ending    = Date.today.to_date

      date_range        = [quarter_beginning, quarter_ending]
		elsif(!quarter.nil? && (/Q[1-4][\_\+\- ]\d\d\d\d/.match(quarter)))
			quarter, quarter_year = quarter.humanize.split(" ")

      quarter_start_dates = ["#{quarter_year}-01-01".to_date, "#{quarter_year}-04-01".to_date, "#{quarter_year}-07-01".to_date, "#{quarter_year}-10-01".to_date]
      quarter_end_dates   = ["#{quarter_year}-03-31".to_date, "#{quarter_year}-06-30".to_date, "#{quarter_year}-09-30".to_date, "#{quarter_year}-12-31".to_date]

      current_quarter   = (quarter.match(/\d+/).to_s.to_i - 1)
      quarter_beginning = quarter_start_dates[current_quarter]
      quarter_ending    = quarter_end_dates[current_quarter]

      date_range = [quarter_beginning, quarter_ending]

    end

    return date_range
  end

  def self.cohort_range(date)
    year = date.year
    if date >= "#{year}-01-01".to_date and date <= "#{year}-03-31".to_date
      quarter = "Q1 #{year}"
    elsif date >= "#{year}-04-01".to_date and date <= "#{year}-06-30".to_date
      quarter = "Q2 #{year}"
    elsif date >= "#{year}-07-01".to_date and date <= "#{year}-09-30".to_date
      quarter = "Q3 #{year}"
    elsif date >= "#{year}-10-01".to_date and date <= "#{year}-12-31".to_date
      quarter = "Q4 #{year}"
    end
    self.generate_cohort_date_range(quarter)
  end

  def self.generate_cohort_quarters(start_date, end_date)
    cohort_quarters   = []
    current_quarter   = ""
    quarter_end_dates = ["#{end_date.year}-03-31".to_date, "#{end_date.year}-06-30".to_date, "#{end_date.year}-09-30".to_date, "#{end_date.year}-12-31".to_date]

    quarter_end_dates.each_with_index do |quarter_end_date, quarter|
      (current_quarter = (quarter + 1) and break) if end_date < quarter_end_date
    end

    quarter_number  =  current_quarter
    cohort_quarters += ["Cumulative"]
    current_date    =  end_date

    begin
      cohort_quarters += ["Q#{quarter_number} #{current_date.year}"]
      (quarter_number > 1) ? quarter_number -= 1: (current_date = current_date - 1.year and quarter_number = 4)
    end while (current_date.year >= start_date.year)

    cohort_quarters
  end


=begin

"SELECT age,gender,count(*) AS total FROM 
            (SELECT age_group(p.birthdate,date(obs.obs_datetime),Date(p.date_created),p.birthdate_estimated) 
            as age,p.gender AS gender
            FROM `encounter` INNER JOIN obs ON obs.encounter_id=encounter.encounter_id
            INNER JOIN patient p ON p.patient_id=encounter.patient_id WHERE
            (encounter_datetime >= '#{start_date}' AND encounter_datetime <= '#{end_date}' 
            AND encounter_type=#{enc_type_id} AND obs.voided=0) GROUP BY encounter.patient_id 
            order by age) AS t group by t.age,t.gender"
=end




  def self.opd_diagnosis(start_date , end_date , groups = ['> 14 to < 20'] )
    age_groups = groups.map{|g|"'#{g}'"}
    concept = ConceptName.find_by_name("DIAGNOSIS").concept_id

=begin
    observations = Observation.find(:all,:joins => "INNER JOIN person p ON p.person_id = obs.person_id
                   INNER JOIN concept_name c ON obs.value_coded = c.concept_id",
                   :select => "value_coded diagnosis , 
                    (SELECT age_group(p.birthdate,LEFT(obs.obs_datetime,10),LEFT(p.date_created,10),p.birthdate_estimated) patient_groups",
                   :conditions => ["concept_id = ? AND obs_datetime >= ? AND obs_datetime <= ?",
                   concept , start_date.strftime('%Y-%m-%d 00:00:00') , end_date.strftime('%Y-%m-%d 23:59:59') ],
                   :group => "diagnosis HAVING patient_groups IN (#{age_groups.join(',')})",
                   :order => "diagnosis ASC")
=end

    observations = Observation.find_by_sql(["SELECT name diagnosis , 
age_group(p.birthdate,DATE(obs_datetime),DATE(p.date_created),p.birthdate_estimated) age_groups 
FROM `obs` 
INNER JOIN person p ON obs.person_id = obs.person_id
INNER JOIN concept_name c ON c.concept_name_id = obs.value_coded_name_id
WHERE (obs.concept_id=#{concept} 
AND obs_datetime >= '#{start_date.strftime('%Y-%m-%d 00:00:00')}'
AND obs_datetime <= '#{end_date.strftime('%Y-%m-%d 23:59:59')}' AND obs.voided = 0) 
GROUP BY diagnosis,age_groups
HAVING age_groups IN (#{age_groups.join(',')})
ORDER BY c.name ASC"])


    return {} if observations.blank?
    results = Hash.new(0)
    observations.map do | obs |
      results[obs.diagnosis] += 1
    end
    results
  end


  def self.opd_diagnosis_by_location(diagnosis , start_date , end_date , groups = ['> 14 to < 20'] )
    age_groups = groups.map{|g|"'#{g}'"}
    concept = ConceptName.find_by_name("DIAGNOSIS").concept_id

=begin
    observations = Observation.find(:all,:joins => "INNER JOIN person p ON p.person_id = obs.person_id
                   INNER JOIN concept_name c ON obs.value_coded = c.concept_id",
                   :select => "value_coded diagnosis , 
                    (SELECT age_group(p.birthdate,LEFT(obs.obs_datetime,10),LEFT(p.date_created,10),p.birthdate_estimated) patient_groups",
                   :conditions => ["concept_id = ? AND obs_datetime >= ? AND obs_datetime <= ?",
                   concept , start_date.strftime('%Y-%m-%d 00:00:00') , end_date.strftime('%Y-%m-%d 23:59:59') ],
                   :group => "diagnosis HAVING patient_groups IN (#{age_groups.join(',')})",
                   :order => "diagnosis ASC")
=end

    observations = Observation.find_by_sql(["SELECT name diagnosis , city_village village , 
age_group(p.birthdate,DATE(obs_datetime),DATE(p.date_created),p.birthdate_estimated) age_groups 
FROM `obs` 
INNER JOIN person p ON obs.person_id = obs.person_id
INNER JOIN concept_name c ON c.concept_name_id = obs.value_coded_name_id
INNER JOIN person_address pd ON obs.person_id = pd.person_id
WHERE (obs.concept_id=#{concept} 
AND obs_datetime >= '#{start_date.strftime('%Y-%m-%d 00:00:00')}'
AND obs_datetime <= '#{end_date.strftime('%Y-%m-%d 23:59:59')}' AND obs.voided = 0) 
GROUP BY diagnosis , village ,age_groups
HAVING age_groups IN (#{age_groups.join(',')}) AND diagnosis = ?
ORDER BY c.name ASC",diagnosis])


    return {} if observations.blank?
    results = Hash.new(0)
    observations.map do | obs |
      results["#{obs.village}::#{obs.diagnosis}"] += 1
    end
    results
  end

  def self.opd_diagnosis_plus_demographics(diagnosis , start_date , end_date , groups = ['> 14 to < 20'] )
    age_groups = groups.map{|g|"'#{g}'"}
    concept = ConceptName.find_by_name("DIAGNOSIS").concept_id
    attribute_type = PersonAttributeType.find_by_name("Cell Phone Number").id

    observations = Observation.find_by_sql(["SELECT 
p.person_id patient_id , pn.given_name first_name, pn.family_name last_name , p.birthdate, 
LEFT(obs.obs_datetime,10) visit_date, p.gender , pa.value phone_number , cn.name diagnosis,
age(p.birthdate, LEFT(obs_datetime,10),LEFT(p.date_created,10), p.birthdate_estimated) visit_age,
age(p.birthdate, current_date, current_date, p.birthdate_estimated) current_age, 
age_group(p.birthdate, LEFT(obs_datetime,10),LEFT(p.date_created,10), p.birthdate_estimated) age_groups, 
pd.city_village address, (SELECT address2 FROM person_address i WHERE i.person_id = p.person_id limit 1) landmark
FROM `obs`
INNER JOIN concept_name cn ON obs.value_coded_name_id = cn.concept_name_id
INNER JOIN person p ON obs.person_id = p.person_id
INNER JOIN person_attribute pa ON p.person_id = pa.person_id
INNER JOIN person_name pn ON p.person_id = pn.person_id
INNER JOIN person_address pd ON p.person_id = pd.person_id
WHERE (obs.concept_id = ? AND obs.obs_datetime >= ? AND obs.obs_datetime <= ? AND pa.person_attribute_type_id = ?) 
GROUP BY first_name,last_name,birthdate,gender,visit_date,value_coded_name_id
HAVING age_groups IN (#{age_groups.join(',')}) AND diagnosis = ?
ORDER BY age_groups DESC",concept , start_date.strftime('%Y-%m-%d 00:00:00'),
end_date.strftime('%Y-%m-%d 23:59:59'),attribute_type,diagnosis])

    return {} if observations.blank?
    results = Hash.new()
    count = 0
    observations.map do | obs |
      results["#{obs.patient_id}:#{obs.visit_date}"][:diagnosis] << obs.diagnosis unless results["#{obs.patient_id}:#{obs.visit_date}"].blank?
      results["#{obs.patient_id}:#{obs.visit_date}"] = {
                            :name => "#{obs.first_name} #{obs.last_name}",
                            :birthdate => obs.birthdate ,
                            :visit_date => obs.visit_date,
                            :visit_age => obs.visit_age,
                            :current_age => obs.current_age,
                            :phone_number => obs.phone_number,
                            :diagnosis => [obs.diagnosis]  ,
                            :age_group => obs.age_groups,
                            :address => obs.address
                          } if results["#{obs.patient_id}:#{obs.visit_date}"].blank?
    end
    results
  end


  def self.opd_disaggregated_diagnosis(start_date , end_date , groups = ['> 14 to < 20'] )
    age_groups = groups.map{|g|"'#{g}'"}
    concept = ConceptName.find_by_name("DIAGNOSIS").concept_id

    observations = Observation.find_by_sql(["SELECT p.person_id patient_id , p.gender gender , name diagnosis ,  
age_group(p.birthdate,DATE(obs_datetime),DATE(p.date_created),p.birthdate_estimated) age_groups
FROM `obs` 
INNER JOIN person p ON obs.person_id = p.person_id
INNER JOIN concept_name c ON c.concept_name_id = obs.value_coded_name_id
WHERE (obs.concept_id=#{concept} 
AND obs_datetime >= '#{start_date.strftime('%Y-%m-%d 00:00:00')}'
AND obs_datetime <= '#{end_date.strftime('%Y-%m-%d 23:59:59')}' AND obs.voided = 0) 
GROUP BY patient_id , age_groups , diagnosis 
HAVING age_groups IN (#{age_groups.join(',')})
ORDER BY diagnosis ASC"])


    return {} if observations.blank?
    results = Hash.new()
    observations.map do | obs |
      results[obs.diagnosis] = {obs.gender => {
                                 :less_than_six_months => 0,
                                 :six_months_to_five_years => 0,
                                 :five_years_to_fourteen_years => 0,
                                 :over_fourteen_years => 0 
                               }} if results[obs.diagnosis].blank?

     if results[obs.diagnosis][obs.gender].blank?
       results[obs.diagnosis] = {obs.gender => {
                                  :less_than_six_months => 0,
                                  :six_months_to_five_years => 0,
                                  :five_years_to_fourteen_years => 0,
                                  :over_fourteen_years => 0 
                                }} 
     end 


     case obs.age_groups
        when "< 6 months" 
          results[obs.diagnosis][obs.gender][:less_than_six_months]+=1
        when "6 months to < 1 yr" , "1 to < 5"
          results[obs.diagnosis][obs.gender][:six_months_to_five_years]+=1
        when "5 to 14"
          results[obs.diagnosis][obs.gender][:five_years_to_fourteen_years]+=1
        else
          results[obs.diagnosis][obs.gender][:over_fourteen_years]+=1
      end
    
    end
    results
  end

  def self.opd_referrals(start_date , end_date)
    concept = ConceptName.find_by_name("REFERRAL CLINIC IF REFERRED").concept_id

    observations = Observation.find_by_sql(["SELECT value_text clinic , count(*) total
FROM `obs` 
INNER JOIN concept_name c ON c.concept_name_id = obs.concept_id
WHERE (obs.concept_id=#{concept} 
AND obs_datetime >= '#{start_date.strftime('%Y-%m-%d 00:00:00')}'
AND obs_datetime <= '#{end_date.strftime('%Y-%m-%d 23:59:59')}' AND obs.voided = 0) 
GROUP BY clinic
ORDER BY clinic ASC"])


    return {} if observations.blank?
    results = Hash.new()
    observations.map do | obs |
      results[obs.clinic] = 1
    end
    results
  end

  def self.set_appointments(date = Date.today,identifier_type = 'Filing number')
    concept_id = ConceptName.find_by_name("Appointment date").concept_id
    records = Observation.find(:all,:joins =>"INNER JOIN person p 
      ON p.person_id = obs.person_id
      INNER JOIN person_name n ON p.person_id=n.person_id                                 
      RIGHT JOIN patient_identifier i ON i.patient_id = obs.person_id 
      AND i.identifier_type = (SELECT patient_identifier_type_id 
      FROM patient_identifier_type pi WHERE pi.name = '#{identifier_type}')",
      :conditions =>["obs.concept_id=? AND value_datetime >= ? AND value_datetime <=?",
      concept_id,date.strftime('%Y-%m-%d 00:00:00'),date.strftime('%Y-%m-%d 23:59:59')],
      :select =>"obs.obs_id obs_id,obs.person_id patient_id,n.given_name first_name,n.family_name last_name, 
      p.gender gender,p.birthdate birthdate, obs.obs_datetime visit_date , i.identifier identifier",
      :order => "obs.obs_datetime DESC")

    demographics = {}
    (records || []).each do |r|
      demographics[r.obs_id] = {:first_name => r.first_name,
                            :last_name => r.last_name,
                            :gender => r.gender,
                            :birthdate => r.birthdate,
                            :visit_date => r.visit_date,
                            :patient_id => r.patient_id,
                            :identifier => r.identifier}
    end
    return demographics
  end
    
  def self.investigations(order_concept_name,month,year = Date.today.year)
   order_type_id = OrderType.find_by_name("RADIOLOGY").order_type_id
   order_concept_id = ConceptName.find_by_name(order_concept_name).concept_id
   radiology_examination_encounter_id = EncounterType.find_by_name("RADIOLOGY EXAMINATION").encounter_type_id
   examination_concept_id = ConceptName.find_by_name("EXAMINATION").concept_id
   start_days = [1, 8, 15, 22, 29]
   weeks = Hash.new()
   
    start_days.each_with_index do|day,count|
      weeks[count] = Hash.new()

      if month == 2 and day == 29 and !Date.leap?(year)
        return weeks
      end
      
      start_date = "#{day}-#{month}-#{year}".to_date.strftime("%Y-%m-%d 00:00:00")
      if month == 2 and day == 29 and Date.leap?(start_date.to_date.year)
        end_date = "#{Time.days_in_month(month)}-#{month}-#{year}".to_date.strftime("%Y-%m-%d 23:59:59")  
      elsif day == 29
         end_date = "#{Time.days_in_month(month)}-#{month}-#{year}".to_date.strftime("%Y-%m-%d 23:59:59")
      else
         end_date = ((start_date.to_date + 1.week) - 1.day).strftime("%Y-%m-%d 23:59:59")
      end

      obs = Observation.find_by_sql("SELECT cn.name as examination,COUNT(o.value_coded) as cnt FROM obs o
                                     INNER JOIN encounter e
                                     ON o.encounter_id = e.encounter_id
                                     INNER JOIN concept_name cn
                                     ON o.value_coded = cn.concept_id
                                     INNER JOIN orders od
                                     ON od.encounter_id = o.encounter_id
                                     WHERE od.voided = 0
                                     AND od.concept_id = #{order_concept_id}
                                     AND od.order_type_id = #{order_type_id}
                                     AND e.encounter_type = #{radiology_examination_encounter_id}
                                     AND o.concept_id = #{examination_concept_id}
                                     AND o.obs_datetime BETWEEN '#{start_date}' AND '#{end_date}'
                                     GROUP BY cn.name")
     

      obs.each do |ob|
         weeks[count][ob.examination] = ob.cnt
      end
         
    end
    weeks
  end
  
  def self.detailed_investigations(order_concept_name,month,year = Date.today.year)
   order_type_id = OrderType.find_by_name("RADIOLOGY").order_type_id
   order_concept_id = ConceptName.find_by_name(order_concept_name).concept_id
   radiology_examination_encounter_id = EncounterType.find_by_name("RADIOLOGY EXAMINATION").encounter_type_id
   detailed_examination_concept_id = ConceptName.find_by_name("DETAILED EXAMINATION").concept_id
   start_days = [1, 8, 15, 22, 29]
   weeks = Hash.new()
  
    start_days.each_with_index do|day,count|
      weeks[count] = Hash.new()

      if month == 2 and day == 29 and !Date.leap?(year)
        return weeks
      end
      
      start_date = "#{day}-#{month}-#{year}".to_date.strftime("%Y-%m-%d 00:00:00")
      if month == 2 and day == 29 and Date.leap?(start_date.to_date.year)
        end_date = "#{Time.days_in_month(month)}-#{month}-#{year}".to_date.strftime("%Y-%m-%d 23:59:59")  
      elsif day == 29
         end_date = "#{Time.days_in_month(month)}-#{month}-#{year}".to_date.strftime("%Y-%m-%d 23:59:59")
      else
         end_date = ((start_date.to_date + 1.week) - 1.day).strftime("%Y-%m-%d 23:59:59")
      end
      
      
       enema_concept_id = ConceptName.find_by_name('Enema').concept_id
       meal_concept_id  = ConceptName.find_by_name('Meal').concept_id
       swallow_concept_id = ConceptName.find_by_name('Swallow').concept_id
     
       obs = Observation.find_by_sql("SELECT cn.name as examination,COUNT(o.value_coded) as cnt FROM obs o
                                     INNER JOIN encounter e
                                     ON o.encounter_id = e.encounter_id
                                     INNER JOIN concept_name cn
                                     ON o.value_coded = cn.concept_id
                                     INNER JOIN orders od
                                     ON od.encounter_id = o.encounter_id
                                     WHERE od.voided = 0
                                     AND od.concept_id = #{order_concept_id}
                                     AND od.order_type_id = #{order_type_id}
                                     AND e.encounter_type = #{radiology_examination_encounter_id}
                                     AND o.concept_id = #{detailed_examination_concept_id}
                                     AND o.value_coded IN (#{enema_concept_id},#{meal_concept_id},#{swallow_concept_id})
                                     AND o.obs_datetime BETWEEN '#{start_date}' AND '#{end_date}'
                                     GROUP BY cn.name")
     

      obs.each do |ob|
         weeks[count][ob.examination] = ob.cnt
      end
         
    end
    weeks
  end
   
  def self.daily_report(start_date,end_date)
      radiology_order_type_id = OrderType.find_by_name('RADIOLOGY').order_type_id
      radiology_encounter_id = EncounterType.find_by_name('RADIOLOGY EXAMINATION').id
      examination_concept_id = ConceptName.find_by_name('EXAMINATION').concept_id
      xray_concept_id = ConceptName.find_by_name('XRAY').concept_id
      ultrasound_concept_id = ConceptName.find_by_name('ULTRASOUND').concept_id
      ct_concept_id = ConceptName.find_by_name('CT SCAN').concept_id
      mri_concept_id = ConceptName.find_by_name('MRI SCAN').concept_id
      bd_concept_id = ConceptName.find_by_name('BONE DENSITOMETRY').concept_id
      m_concept_id = ConceptName.find_by_name('MAMMOGRAPHY').concept_id

      obs = Observation.find_by_sql("SELECT od.concept_id as order_concept_id,o.value_coded as exam_value_coded,COUNT(o.value_coded) as exam_total FROM obs o
                                      INNER JOIN orders od
                                      ON od.encounter_id = o.encounter_id
                                      INNER JOIN encounter en
                                      ON en.encounter_id = o.encounter_id
                                      AND od.order_type_id = #{radiology_order_type_id}
                                      AND o.concept_id = #{examination_concept_id}
                                      AND en.encounter_type = #{radiology_encounter_id}
                                      AND od.concept_id IN (#{xray_concept_id}, 
																														#{ultrasound_concept_id} ,
																														#{ct_concept_id},
                                                            #{mri_concept_id}, 
																														#{bd_concept_id}, 
																														#{m_concept_id} )
                                      AND od.voided = 0
                                      AND o.voided = 0
                                      AND DATE(o.obs_datetime) BETWEEN '#{start_date}' AND '#{end_date}'
                                      GROUP BY od.concept_id,o.value_coded
                                      ORDER BY od.concept_id DESC") rescue nil
  
     
       @exam_line = []
     obs.each do |ob|
       @exam_line << [ConceptName.find_by_concept_id(ob[:order_concept_id]).name,ConceptName.find_by_concept_id(ob[:exam_value_coded]).name,ob[:exam_total]]
     end
       @exam_line
  end
  def self.revenue_collected(start_date,end_date)
    payment_amount_concept_id = ConceptName.find_by_name("PAYMENT AMOUNT").concept_id
    invoice_amount_concept_id = ConceptName.find_by_name("INVOICE AMOUNT").concept_id
    Observation.find_by_sql("SELECT SUM(o.value_numeric) as total_revenue FROM obs o
                             WHERE o.voided = 0 AND o.concept_id IN (#{payment_amount_concept_id},#{invoice_amount_concept_id})
                             AND o.obs_datetime BETWEEN '#{start_date}' AND '#{end_date}'
                             GROUP BY o.concept_id") rescue 0.0
  end
  
  def self.film_used(film_state_id,month,year = Date.today.year)
    film_encounter_id = EncounterType.find_by_name('FILM').id
    film_state_concept_id = film_state_id
    start_days = [1, 8, 15, 22, 29]
    weeks = Hash.new()

    start_days.each_with_index do|day,count|
      weeks[count] = Hash.new()

      if month == 2 and day == 29 and !Date.leap?(year)
        return weeks
      end

      start_date = "#{day}-#{month}-#{year}".to_date.strftime("%Y-%m-%d 00:00:00")
      if month == 2 and day == 29 and Date.leap?(start_date.to_date.year)
        end_date = "#{Time.days_in_month(month)}-#{month}-#{year}".to_date.strftime("%Y-%m-%d 23:59:59")
      elsif day == 29
         end_date = "#{Time.days_in_month(month)}-#{month}-#{year}".to_date.strftime("%Y-%m-%d 23:59:59")
      else
         end_date = ((start_date.to_date + 1.week) - 1.day).strftime("%Y-%m-%d 23:59:59")
      end

      obs = Observation.find_by_sql("SELECT cnnn.name AS film_size,cn.name AS film_state,SUM(o.value_numeric) AS cnt FROM obs o
                                    INNER JOIN obs oo ON
                                    oo.obs_id = o.obs_group_id
                                    INNER JOIN concept_name cnnn
                                    on cnnn.concept_id = oo.value_coded
                                    INNER JOIN encounter e
                                    on o.encounter_id = e.encounter_id
                                    INNER JOIN concept_name cn
                                    on o.concept_id = cn.concept_id
                                    WHERE e.encounter_type =  #{film_encounter_id} AND o.concept_id = #{film_state_concept_id} AND
                                    e.encounter_datetime BETWEEN '#{start_date}' AND '#{end_date}' AND o.voided = 0 AND e.voided = 0
                                    GROUP BY cnnn.name")

      obs.each do |ob|
         weeks[count][ob.film_size] = ob.cnt
      end

    end
   weeks
  end
  
end
