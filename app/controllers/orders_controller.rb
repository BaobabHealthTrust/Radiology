class OrdersController < ApplicationController
  def new

  end

  def create
    patient = Patient.find(params[:encounter][:patient_id] || session[:patient_id]) rescue nil
    unless params[:location]
      session_date = session[:datetime] || Time.now()
    else
      session_date = params[:encounter_datetime] #Use date_created passed during import
    end

    # set current location via params if given
    Location.current_location = Location.find(params[:location]) if params[:location]

    if params[:filter] and !params[:filter][:provider].blank?

      user_person_id = User.find_by_username(params[:filter][:provider]).person_id
    elsif params[:location]
      user_person_id = params[:provider_id]
    else
      user_person_id = current_user.person_id
    end

    encounter_type_name = params[:encounter][:encounter_type_name]
    encounter = create_encounter(encounter_type_name, patient, session_date, user_person_id)
    create_obs(encounter, params)

    radiology_test = ConceptName.find_by_name("RADIOLOGY TEST").concept_id
    order_type_concept = Observation.find( :first, :select => "concept_id, value_coded",
                                           :conditions => ["encounter_id = ? AND concept_id = ?",
                                            encounter.encounter_id, radiology_test]).answer_concept

    examination_number = next_available_exam_number
    order = current_radiology_order(examination_number, order_type_concept, patient, encounter)

    print_and_redirect("/orders/examination_number?order_id=#{order.order_id}", "/clinic")

  end
  
  def examination_number
    print_string = examination_number_label(params[:order_id])
    send_data(print_string,:type=>"application/label; charset=utf-8",:stream=> false, 
      :filename=>"#{params[:order_id]}#{rand(10000)}.lbl",:disposition => "inline")
  end

  def examination_print
    print_and_redirect("/orders/examination_number?order_id=#{params[:order_id]}", "/patients/show/#{params[:patient_id]}")
  end

  def create_encounter(encounter_type_name,patient, date = Time.now(), provider = current_user.person_id)
    type = EncounterType.find_by_name(encounter_type_name)
    encounter = patient.encounters.create(:encounter_type => type.id,:encounter_datetime => date, :provider_id => provider)
  end

  def current_radiology_order(examination_number, concept = nil, patient = nil, encounter = nil)
    type = OrderType.find_by_name("RADIOLOGY")
    order = patient.orders.find_by_accession_number(examination_number)
    order ||= patient.orders.create(:order_type_id => type.id,
                                    :patient_id => patient.patient_id,
                                    :concept_id => concept.concept_id,
                                    :encounter_id => encounter.encounter_id,
                                    :orderer => current_user.user_id,
                                    :accession_number => examination_number,
                                    :start_date => encounter.encounter_datetime)
  end

  def next_available_exam_number
    prefix = 'R'
    last_exam_num = Order.find(:first, :order => "accession_number DESC",
                   :conditions => ["voided = 0"]
                   ).accession_number rescue []

    index = 0
    last_exam_num.each_char do | c |
      next if c == prefix
      break unless c == '0'
      index+=1
    end unless last_exam_num.blank?

    last_exam_num = '0' if last_exam_num.blank?
    prefix + (last_exam_num[index..-1].to_i + 1).to_s.rjust(8,'0')
  end

  def examination_number_label(order_id)
    order = Order.find(order_id)
    encounter_id = order.encounter.encounter_id

    referred_from_concept = ConceptName.find_by_name("REFERRED FROM").concept_id
    referred_from = Observation.find( :first, :select => "concept_id, value_text",
                                           :conditions => ["encounter_id = ? AND concept_id = ?",
                                            encounter_id, referred_from_concept]).value_text

    examination_concept = ConceptName.find_by_name("DETAILED EXAMINATION").concept_id
    examination_obs = Observation.find( :first, :select => "concept_id, value_coded",
                                           :conditions => ["encounter_id = ? AND concept_id = ?",
                                             encounter_id, examination_concept])
    examination = examination_obs.answer_concept.shortname rescue nil
    if examination.blank?
      examination = examination_obs.answer_concept.fullname rescue nil
    end

    if examination.blank?
      examination_concept = ConceptName.find_by_name("EXAMINATION").concept_id
      examination_obs = Observation.find( :first, :select => "concept_id, value_coded",
                                             :conditions => ["encounter_id = ? AND concept_id = ?",
                                               encounter_id, examination_concept])
      examination = examination_obs.answer_concept.shortname rescue nil
      if examination.blank?
        examination = examination_obs.answer_concept.fullname rescue ''
      end
    end

    patient_bean = PatientService.get_patient(order.encounter.patient.person)
    return unless patient_bean.national_id
    sex =  patient_bean.sex.match(/F/i) ? "(F)" : "(M)"
    address = patient.person.address.strip[0..24].humanize rescue ""
    #name_of_referring_site = referred_from
    session_date = order.encounter.encounter_datetime.strftime('%d-%b-%Y')
    # study_type = order.concept.fullname

    type = order.concept.fullname
    
    label = ZebraPrinter::StandardLabel.new
    label.font_size = 3
    label.x = 200
    label.font_horizontal_multiplier = 1
    label.font_vertical_multiplier = 1
    label.left_margin = 100
    label.draw_barcode(50,180,0,1,5,15,90,false,"#{order.accession_number}")
    label.draw_multi_text("#{patient_bean.name.titleize}")
    label.draw_multi_text("#{patient_bean.national_id_with_dashes} #{sex} #{patient_bean.birth_date}")
    label.draw_multi_text("#{type} - #{examination}")
    label.draw_multi_text("#{session_date}, #{order.accession_number} (#{referred_from})")
    label.print(1)
  end
   
  def create_obs(encounter , params)
		# Observation handling
		#raise params.to_yaml
		(params[:observations] || []).each do |observation|
			# Check to see if any values are part of this observation
			# This keeps us from saving empty observations
			values = ['coded_or_text', 'coded_or_text_multiple', 'group_id', 'boolean', 'coded', 'drug', 'datetime', 'numeric', 'modifier', 'text'].map { |value_name|
				observation["value_#{value_name}"] unless observation["value_#{value_name}"].blank? rescue nil
			}.compact

			next if values.length == 0

			observation[:value_text] = observation[:value_text].join(", ") if observation[:value_text].present? && observation[:value_text].is_a?(Array)
			observation.delete(:value_text) unless observation[:value_coded_or_text].blank?
			observation[:encounter_id] = encounter.id
			observation[:obs_datetime] = encounter.encounter_datetime || Time.now()
			observation[:person_id] ||= encounter.patient_id
			observation[:concept_name].upcase ||= "DIAGNOSIS" if encounter.type.name.upcase == "OUTPATIENT DIAGNOSIS"

			# Handle multiple select

			if observation[:value_coded_or_text_multiple] && observation[:value_coded_or_text_multiple].is_a?(String)
				observation[:value_coded_or_text_multiple] = observation[:value_coded_or_text_multiple].split(';')
			end

			if observation[:value_coded_or_text_multiple] && observation[:value_coded_or_text_multiple].is_a?(Array)
				observation[:value_coded_or_text_multiple].compact!
				observation[:value_coded_or_text_multiple].reject!{|value| value.blank?}
			end

			# convert values from 'mmol/litre' to 'mg/declitre'
			if(observation[:measurement_unit])
				observation[:value_numeric] = observation[:value_numeric].to_f * 18 if ( observation[:measurement_unit] == "mmol/l")
				observation.delete(:measurement_unit)
			end

			if(observation[:parent_concept_name])
				concept_id = Concept.find_by_name(observation[:parent_concept_name]).id rescue nil
				observation[:obs_group_id] = Observation.find(:first, :conditions=> ['concept_id = ? AND encounter_id = ?',concept_id, encounter.id]).id rescue ""
				observation.delete(:parent_concept_name)
			end

			extracted_value_numerics = observation[:value_numeric]
			extracted_value_coded_or_text = observation[:value_coded_or_text]

      #TODO : Added this block with Yam, but it needs some testing.
      if params[:location]
        if encounter.encounter_type == EncounterType.find_by_name("ART ADHERENCE").id
          passed_concept_id = Concept.find_by_name(observation[:concept_name]).concept_id rescue -1
          obs_concept_id = Concept.find_by_name("AMOUNT OF DRUG BROUGHT TO CLINIC").concept_id rescue -1
          if observation[:order_id].blank? && passed_concept_id == obs_concept_id
            order_id = Order.find(:first,
                                  :select => "orders.order_id",
                                  :joins => "INNER JOIN drug_order USING (order_id)",
                                  :conditions => ["orders.patient_id = ? AND drug_order.drug_inventory_id = ?
                                                  AND orders.start_date < ?", encounter.patient_id,
                                                  observation[:value_drug], encounter.encounter_datetime.to_date],
                                  :order => "orders.start_date DESC").order_id rescue nil
            if !order_id.blank?
              observation[:order_id] = order_id
            end
          end
        end
      end

			if observation[:value_coded_or_text_multiple] && observation[:value_coded_or_text_multiple].is_a?(Array) && !observation[:value_coded_or_text_multiple].blank?
				values = observation.delete(:value_coded_or_text_multiple)
				values.each do |value|
					observation[:value_coded_or_text] = value
					if observation[:concept_name].humanize == "Tests ordered"
						observation[:accession_number] = Observation.new_accession_number
					end

					observation = update_observation_value(observation)

					Observation.create(observation)
				end
			elsif extracted_value_numerics.class == Array
				extracted_value_numerics.each do |value_numeric|
					observation[:value_numeric] = value_numeric

				  if !observation[:value_numeric].blank? && !(Float(observation[:value_numeric]) rescue false)
						observation[:value_text] = observation[:value_numeric]
						observation.delete(:value_numeric)
					end

					Observation.create(observation)
				end
			else
				observation.delete(:value_coded_or_text_multiple)
				observation = update_observation_value(observation) if !observation[:value_coded_or_text].blank?

		    if !observation[:value_numeric].blank? && !(Float(observation[:value_numeric]) rescue false)
					observation[:value_text] = observation[:value_numeric]
					observation.delete(:value_numeric)
				end

				Observation.create(observation)
			end
		end
  end

	def update_observation_value(observation)
		value = observation[:value_coded_or_text]
		value_coded_name = ConceptName.find_by_name(value)

		if value_coded_name.blank?
			observation[:value_text] = value
		else
			observation[:value_coded_name_id] = value_coded_name.concept_name_id
			observation[:value_coded] = value_coded_name.concept_id
		end
		observation.delete(:value_coded_or_text)
		return observation
	end

end
