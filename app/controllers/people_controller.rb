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
					found_person = PatientService.create_from_form(found_person_data['person']) unless found_person_data.blank?
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

		records_per_page = CoreService.get_global_property_value('records_per_page') || 5
		@relation = params[:relation]
		@people = PatientService.person_search(params)
		@patients = []

    unless @people.nil?
			@current_page = @people.paginate(:page => params[:page], :per_page => records_per_page.to_i)
		end

		@current_page.each do | person |
			patient = PatientService.get_patient(person) rescue nil
			@patients << patient
		end

	end

end
