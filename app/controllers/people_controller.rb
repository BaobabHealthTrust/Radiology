class PeopleController < GenericPeopleController
  
  def demographics
    # Search by the demographics that were passed in and then return demographics
    people = PatientService.find_person_by_demographics(params)
    result = people.empty? ? {} : PatientService.demographics(people.first)
    render :text => result.to_json
  end

  def confirm
    session_date = session[:datetime] || Date.today
    if request.post?
      redirect_to search_complete_url(params[:found_person_id], params[:relation]) and return
    end
    
    @found_person_id = params[:found_person_id] 
    @relation = params[:relation]
    @person = Person.find(@found_person_id) rescue nil
    @task = main_next_task(Location.current_location, @person.patient, session_date.to_date)
    @arv_number = PatientService.get_patient_identifier(@person, 'ARV Number')
	  @patient_bean = PatientService.get_patient(@person)
    render :layout => 'menu'

  end
=begin
  def create
    success = false
    Person.session_datetime = session[:datetime].to_date rescue Date.today

    #for now BART2 will use BART1 for patient/person creation until we upgrade BART1 to 2
    #if GlobalProperty.find_by_property('create.from.remote') and property_value == 'yes'
    #then we create person from remote machine
    if create_from_remote
      person_from_remote = PatientService.create_remote_person(params)
      person = PatientService.create_from_form(person_from_remote["person"]) unless person_from_remote.blank?

      if !person.blank?
        success = true
        person.patient.remote_national_id
      end
    else
      success = true
      person = PatientService.create_from_form(params[:person])
    end

    if params[:person][:patient] && success
      PatientService.patient_national_id_label(person.patient)
      unless (params[:relation].blank?)
        redirect_to search_complete_url(person.id, params[:relation]) and return
      else
 #Disable use of filing number and tb session because
 #they are not needed in radiology
       tb_session = false
       use_filing_number = false
       if current_user.activities.include?('Manage Lab Orders') or current_user.activities.include?('Manage Lab Results') or
        current_user.activities.include?('Manage Sputum Submissions') or current_user.activities.include?('Manage TB Clinic Visits') or
         current_user.activities.include?('Manage TB Reception Visits') or current_user.activities.include?('Manage TB Registration Visits') or
          current_user.activities.include?('Manage HIV Status Visits')
         tb_session = true
       end

        if use_filing_number and not tb_session
          PatientService.set_patient_filing_number(person.patient) 
          archived_patient = PatientService.patient_to_be_archived(person.patient)
          message = PatientService.patient_printing_message(person.patient,archived_patient,creating_new_patient = true)
          unless message.blank?
            print_and_redirect("/patients/filing_number_and_national_id?patient_id=#{person.id}" , next_task(person.patient),message,true,person.id)
          else
            print_and_redirect("/patients/filing_number_and_national_id?patient_id=#{person.id}", next_task(person.patient)) 
          end
        else
          print_and_redirect("/patients/national_id_label?patient_id=#{person.id}", next_task(person.patient))
        end
      end
    else
      # Does this ever get hit?
      redirect_to :action => "index"
    end
  end
=end
  def find_by_exam_number                                                       
    if request.post?
      index = 0 ; last_exam_num = params[:exam_number]                          
      last_exam_num.each_char do | c |                                          
        next if c == 'R'                                                        
        break unless c == '0'                                                   
        index+=1                                                                
      end unless last_exam_num.blank?                                           
                                                                                
      exam_number = 'R' + (last_exam_num[index..-1].to_s.rjust(8,'0'))          

      order = Order.find(:first,:conditions =>["accession_number = ? AND voided = 0",exam_number])

      if order.blank?
        redirect_to :action => 'find_by_exam_number' and return                 
      else                  
        session[:examination_number] = order.accession_number
 redirect_to :controller => 'patients', :action => 'show',:patient_id => order.patient_id,:encounter_date => order.date_created.to_date and return
      end                                                                      
    end                                                                         
  end
=begin
def search
		found_person = nil
		if params[:identifier]
 
      if  params[:identifier].length == 9 && params[:identifier][0].chr == "R"
         order = Order.find(:first,:conditions =>["accession_number = ? AND voided = 0",params[:identifier]])
         if order
           session[:examination_number] = order.accession_number
           redirect_to :controller => 'patients', :action => 'show',:patient_id => order.patient_id,
                       :encounter_date => order.date_created.to_date,:examination_number => order.accession_number and return
         else
           redirect_to :controller => 'clinic'
         end
      end

			local_results = PatientService.search_by_identifier(params[:identifier])

			if local_results.length > 1
				@people = PatientService.person_search(params)
			elsif local_results.length == 1
				found_person = local_results.first
			else
				# TODO - figure out how to write a test for this
				# This is sloppy - creating something as the result of a GET
				if create_from_remote
					found_person_data = PatientService.find_remote_person_by_identifier(params[:identifier])
					found_person = PatientService.create_from_form(found_person_data['person']) unless found_person_data.nil?
				end
			end
			if found_person
        patient = DDEService::Patient.new(found_person.patient)
        patient.check_old_national_id(params[:identifier])
				if params[:relation]
					redirect_to search_complete_url(found_person.id, params[:relation]) and return
				else
					redirect_to :action => 'confirm', :found_person_id => found_person.id, :relation => params[:relation] and return
				end
			end
		end

		@relation = params[:relation]
		@people = PatientService.person_search(params)
		@patients = []
		@people.each do | person |
			patient = PatientService.get_patient(person) rescue nil
			@patients << patient
		end

	end
=end
  def search
		found_person = nil
		if params[:identifier]
			local_results = PatientService.search_by_identifier(params[:identifier])
			if local_results.length > 1
				@people = PatientService.person_search(params)
			elsif local_results.length == 1
				found_person = local_results.first
			else
				# TODO - figure out how to write a test for this
				# This is sloppy - creating something as the result of a GET
				if create_from_remote
					found_person_data = PatientService.find_remote_person_by_identifier(params[:identifier])
					found_person = PatientService.create_from_form(found_person_data['person']) unless found_person_data.blank?
				end
			end
			if found_person

        patient = DDEService::Patient.new(found_person.patient)

        national_id_replaced = patient.check_old_national_id(params[:identifier])

				if params[:relation]
					redirect_to search_complete_url(found_person.id, params[:relation]) and return
        elsif national_id_replaced
          print_and_redirect("/patients/national_id_label?patient_id=#{found_person.id}", next_task(found_person.patient)) and return
        else
					redirect_to :action => 'confirm', :found_person_id => found_person.id, :relation => params[:relation] and return
				end
			end
		end
		@relation = params[:relation]
		@people = PatientService.person_search(params)
    @search_results = {}
    @patients = []

    (PatientService.search_from_remote(params) || []).each do |data|
			results = PersonSearch.new(data["npid"]["value"])
      results.national_id = data["npid"]["value"]
      results.current_residence =data["person"]["data"]["addresses"]["city_village"]
      results.person_id = 0
      results.home_district = data["person"]["data"]["addresses"]["state_province"]
      results.traditional_authority =  data["person"]["data"]["addresses"]["county_district"]
      results.name = data["person"]["data"]["names"]["given_name"] + " " + data["person"]["data"]["names"]["family_name"]
      gender = data["person"]["data"]["gender"]
      results.occupation = data["person"]["data"]["occupation"]
      results.sex = (gender == 'M' ? 'Male' : 'Female')
      results.birthdate_estimated = (data["person"]["data"]["birthdate_estimated"]).to_i
      results.birth_date = birthdate_formatted((data["person"]["data"]["birthdate"]).to_date , results.birthdate_estimated)
      results.birthdate = (data["person"]["data"]["birthdate"]).to_date
      results.age = cul_age(results.birthdate.to_date , results.birthdate_estimated)
      @search_results[results.national_id] = results
    end if create_from_dde_server


		(@people || []).each do | person |
			patient = PatientService.get_patient(person) rescue nil
      next if patient.blank?
			results = PersonSearch.new(patient.national_id || patient.patient_id)
      results.national_id = patient.national_id
      results.birth_date = patient.birth_date
      results.current_residence = patient.current_residence
      results.guardian = patient.guardian
      results.person_id = patient.person_id
      results.home_district = patient.home_district
      results.traditional_authority = patient.traditional_authority
      results.mothers_surname = patient.mothers_surname
      results.dead = patient.dead
      results.arv_number = patient.arv_number
      results.eid_number = patient.eid_number
      results.pre_art_number = patient.pre_art_number
      results.name = patient.name
      results.sex = patient.sex
      results.age = patient.age
      @search_results.delete_if{|x,y| x == results.national_id}
      @patients << results
		end

		(@search_results || {}).each do |npid , data |
      @patients << data
    end
	end

  protected

  def cul_age(birthdate , birthdate_estimated , date_created = Date.today, today = Date.today)

    # This code which better accounts for leap years
    patient_age = (today.year - birthdate.year) + ((today.month - birthdate.month) + ((today.day - birthdate.day) < 0 ? -1 : 0) < 0 ? -1 : 0)

    # If the birthdate was estimated this year, we round up the age, that way if
    # it is March and the patient says they are 25, they stay 25 (not become 24)
    birth_date = birthdate
    estimate = birthdate_estimated == 1
    patient_age += (estimate && birth_date.month == 7 && birth_date.day == 1  &&
        today.month < birth_date.month && date_created.year == today.year) ? 1 : 0
  end

  def birthdate_formatted(birthdate,birthdate_estimated)
    if birthdate_estimated == 1
      if birthdate.day == 1 and birthdate.month == 7
        birthdate.strftime("??/???/%Y")
      elsif birthdate.day == 15
        birthdate.strftime("??/%b/%Y")
      elsif birthdate.day == 1 and birthdate.month == 1
        birthdate.strftime("??/???/%Y")
      end
    else
      birthdate.strftime("%d/%b/%Y")
    end
  end
end
