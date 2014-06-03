class EncountersController < GenericEncountersController

  def create(params=params, session=session)
    if params[:change_appointment_date] == "true"
      session_date = session[:datetime].to_date rescue Date.today
      type = EncounterType.find_by_name("APPOINTMENT")                            
      appointment_encounter = Observation.find(:first,                            
      :order => "encounter_datetime DESC,encounter.date_created DESC",
      :joins => "INNER JOIN encounter ON obs.encounter_id = encounter.encounter_id",
      :conditions => ["concept_id = ? AND encounter_type = ? AND patient_id = ?
      AND encounter_datetime >= ? AND encounter_datetime <= ?",
      ConceptName.find_by_name('RETURN VISIT DATE').concept_id,
      type.id, params[:encounter]["patient_id"],session_date.strftime("%Y-%m-%d 00:00:00"),             
      session_date.strftime("%Y-%m-%d 23:59:59")]).encounter rescue nil
      unless appointment_encounter.blank?
        appointment_encounter.void("Given a new appointment date")
      end
    end
    
    radiology_type =  params[:observations][0][:value_coded_or_text] rescue nil
     	
    if params['encounter']['encounter_type_name'].upcase == "APPOINTMENT"
      observations = []
      (params[:observations] || []).each do |observation|

        unless observation['concept_name'].blank?
             if observation['concept_name'].upcase == "RETURN VISIT DATE"
         				 observation['value_datetime'] = params[:observations][0][:value_datetime] rescue nil
                 
             end
        observations << observation
        end 
      end
      params[:observations] = observations unless observations.blank?
    end

    
    @patient = Patient.find(params[:encounter][:patient_id]) rescue nil
    if params['encounter']['encounter_type_name'].to_s.upcase == "APPOINTMENT" && !params[:report_url].nil? && !params[:report_url].match(/report/).nil?
        concept_id = ConceptName.find_by_name("RETURN VISIT DATE").concept_id
        encounter_id_s = Observation.find_by_sql("SELECT encounter_id
                       FROM obs
                       WHERE concept_id = #{concept_id} AND person_id = #{@patient.id}
                            AND DATE(value_datetime) = DATE('#{params[:old_appointment]}') AND voided = 0
                       ").map{|obs| obs.encounter_id}.each do |encounter_id|
                                    Encounter.find(encounter_id).void
                       end   
    end

    # Encounter handling
		encounter = Encounter.new(params[:encounter])
		unless params[:location]
		  encounter.encounter_datetime = session[:datetime] unless session[:datetime].blank?
		else
		  encounter.encounter_datetime = params['encounter']['encounter_datetime']
		end

		if params[:filter] and !params[:filter][:provider].blank?
		  user_person_id = User.find_by_username(params[:filter][:provider]).person_id
		elsif params[:location] # Migration
		  user_person_id = encounter[:provider_id]
		else
		  user_person_id = User.find_by_user_id(encounter[:provider_id]).person_id rescue 1
		end
		encounter.provider_id = user_person_id

		encounter.save

    #create observations for the just created encounter
    create_obs(encounter , params)


    unless params[:location]
    #find a way of printing the lab_orders labels
     if params['encounter']['encounter_type_name'] == "LAB ORDERS"
       redirect_to"/patients/print_lab_orders/?patient_id=#{@patient.id}"
     elsif params['encounter']['encounter_type_name'] == "TB suspect source of referral" && !params[:gender].empty? && !params[:family_name].empty? && !params[:given_name].empty?
       redirect_to"/encounters/new/tb_suspect_source_of_referral/?patient_id=#{@patient.id}&gender=#{params[:gender]}&family_name=#{params[:family_name]}&given_name=#{params[:given_name]}"
     else
      if params['encounter']['encounter_type_name'].to_s.upcase == "APPOINTMENT" && !params[:report_url].nil? && !params[:report_url].match(/report/).nil?
         redirect_to  params[:report_url].to_s and return
      elsif params['encounter']['encounter_type_name'].upcase == 'APPOINTMENT'
        appointment_print(encounter,radiology_type)
        return
      end
      redirect_to next_task(@patient)
     end
    else
      if params[:voided]
        encounter.void(params[:void_reason],
                       params[:date_voided],
                       params[:voided_by])
      end
      #made restful the default due to time
      render :text => encounter.encounter_id.to_s and return
      #return encounter.id.to_s  # support non-RESTful creation of encounters
    end
  end

  def appointment
    print_string = appointment_label(params)
    send_data(print_string,:type=>"application/label; charset=utf-8",:stream=> false, 
      :filename=>"#{params[:encounter_id]}#{rand(10001)}.lbl",:disposition => "inline")
  end

  def appointment_print(encounter,radiology_type)
    print_and_redirect("/encounters/appointment?encounter_id=#{encounter.id}&rad_type=#{radiology_type}", "/patients/show/#{encounter.patient_id}")
  end
  
  def appointment_label(encounter_id)
    encounter = Encounter.find(params["encounter_id"])
    encounter_id = encounter.id

    examination_concept = ConceptName.find_by_name("EXAMINATION").concept_id
    examination_obs = Observation.find( :first, :select => "concept_id, value_coded",
                                             :conditions => ["encounter_id = ? AND concept_id = ?",
                                               encounter_id, examination_concept])
    examination = examination_obs.answer_concept.shortname rescue ''
    
    if examination.blank?
      examination = examination_obs.answer_concept.fullname rescue ''
    end

    detailed_examination_concept = ConceptName.find_by_name("DETAILED EXAMINATION").concept_id
    detailed_examination_obs = Observation.find( :first, :select => "concept_id, value_coded",
                                           :conditions => ["encounter_id = ? AND concept_id = ?",
                                             encounter_id, detailed_examination_concept])
    detailed_examination = detailed_examination_obs.answer_concept.shortname rescue nil
    if detailed_examination.blank?
      detailed_examination = detailed_examination_obs.answer_concept.fullname rescue nil
    end
     
    appointment_concept = ConceptName.find_by_name("APPOINTMENT DATE").concept_id
    appointment_date_obs = Observation.find( :first, :select => "concept_id, value_datetime",
                                             :conditions => ["encounter_id = ? AND concept_id = ?",
                                               encounter_id,  appointment_concept])
    appointment_date = appointment_date_obs.value_datetime.strftime('%A, %d %b %Y')
    
    if params["rad_type"]
       radiology_type = ConceptName.find_by_name(params["rad_type"])
       type = radiology_type.concept.shortname
       type = radiology_type.concept.fullname if type.blank?
    end 

    patient_bean = PatientService.get_patient(encounter.patient.person)
    return unless patient_bean.national_id
    sex =  patient_bean.sex.match(/F/i) ? "(F)" : "(M)"
    address = patient.person.address.strip[0..24].humanize rescue ""
    session_date = encounter.encounter_datetime.strftime('%d-%b-%Y')
    
    
    label = ZebraPrinter::StandardLabel.new
    label.font_size = 4
    label.x = 50
    label.font_horizontal_multiplier = 1
    label.font_vertical_multiplier = 1
    label.left_margin = 100
    label.draw_barcode(150,220,0,1,5,15,90,false,"#{patient_bean.national_id}")
    label.draw_multi_text("#{patient_bean.name.titleize} #{sex} ")
    label.draw_multi_text("#{patient_bean.national_id_with_dashes} DOB #{patient_bean.birth_date}")
   
    label.draw_multi_text("Appointment : #{type}")
    
    unless detailed_examination.blank?
      label.draw_multi_text("Examination : #{examination}-#{detailed_examination}")
    else
      label.draw_multi_text("Examination : #{examination}")
    end

    label.draw_multi_text("Appointment Date : #{appointment_date}")
   
    label.print(1)
  end

end
