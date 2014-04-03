class PatientsController < GenericPatientsController

  def personal
    @links = []
    patient = Patient.find(params[:id])
    order_type = OrderType.find_by_name("RADIOLOGY")
    order = Order.find(:first,:conditions => ["patient_id = ? AND order_type_id = ? AND voided = 0",patient.id,order_type.order_type_id],:order => "start_date DESC")
    if use_user_selected_activities
      @links << ["Change User Activities","/user/activities/#{current_user.id}?patient_id=#{patient.id}"]
    end
      @links << ["National ID","/patients/dashboard_print_national_id/#{patient.id}"]
    unless order.nil?
      #@links << ["Examination Label","/orders/examination_number?order_id=#{order.order_id}"]
      @links << ["Examination Labels","/patients/previous_examinations/#{patient.id}"]
    end
    render :template => 'dashboards/personal_tab', :layout => false
  end

  def previous_examinations
     @patient = Patient.find(params[:id])
     orders = Order.find(:all,:conditions => ["patient_id = ? AND voided = 0",@patient.id],:order => "date_created DESC LIMIT 5")
     @orders = []
     orders.each  do |order|
       @orders << [order.order_id, order.accession_number]
     end
  end
  
  def examination
    exam_number = params[:examination_number]
    @order = Order.find(:first,:conditions => ["accession_number = ? AND voided = 0",exam_number])
    @patient = Patient.find(@order.patient_id)
    @encounter_date = params[:encounter_date]
  end

  def print_investigation
    # render :layout => "dynamic-dashboard"
  end

  def investigations_printable
    order = Order.find(:first,:conditions => ["accession_number = ? AND voided = 0",params["examination_number"]])
    notes_concept_id = ConceptName.find_by_name("NOTES").concept_id
    findings_concept_id = ConceptName.find_by_name("FINDINGS").concept_id
    examination_concept_id = ConceptName.find_by_name("EXAMINATION").concept_id
    detailed_examination = ConceptName.find_by_name("DETAILED EXAMINATION").concept_id
    @patient = Patient.find(params[:patient_id]) rescue nil
		@patient_bean = PatientService.get_patient(@patient.person)

    # Details specified in config/application.yml
    @facility = CoreService.get_global_property_value("current.health.facility") rescue ""
    @hod = CoreService.get_global_property_value("hod") rescue ""
    @addressl1 = CoreService.get_global_property_value("facility.address.l1") rescue ""
    @addressl2 = CoreService.get_global_property_value("facility.address.l2") rescue ""
    @tel = CoreService.get_global_property_value("facility.tel") rescue ""
    @fax = CoreService.get_global_property_value("facility.fax") rescue ""
    @footer = CoreService.get_global_property_value("footer") rescue ""

    # Assuming the test/procedure identifier is passed as a parameter, details are reflected here
    @reportdate = (params["encounter_date"].to_date rescue Date.today).strftime("%d-%b-%Y") rescue ""
    @examination_type = ConceptName.find_by_concept_id(order.concept_id).name
    @examination =  Observation.find(:first,:conditions => ["encounter_id = ? AND concept_id = ? AND voided = 0",order.encounter_id,examination_concept_id]).name rescue ""
    @detailed_examination = Observation.find(:first,:conditions => ["encounter_id = ? AND concept_id = ? AND voided = 0",order.encounter_id,detailed_examination]).name rescue ""
    @test_date = (order.date_created rescue Date.today).strftime("%d-%b-%Y") rescue ""
    @full_test_name = @test_type rescue "&nbsp;"
    @provider_title = "Radiologist"

    @findings = Observation.find(:all,:conditions => ["order_id = ? AND concept_id = ? AND voided = 0",order.order_id,findings_concept_id]) rescue "&nbsp;"
    @comments = Observation.find(:all,:conditions => ["order_id = ? AND concept_id = ? AND voided = 0",order.order_id,notes_concept_id]) rescue "&nbsp;"

    @provider = current_user.name.upcase rescue "&nbsp;"

    render :layout => false
  end

  def print_note
    # raise request.remote_ip.to_yaml
    location = request.remote_ip rescue ""
    @patient = Patient.find(params[:patient_id] || session[:patient_id]) rescue nil
    @user = current_user.user_id
    if @patient
      current_printer = ""
      wards = GlobalProperty.find_by_property("facility.ward.printers").property_value.split(",") rescue []
      printers = wards.each{|ward|
        current_printer = ward.split(":")[1] if ward.split(":")[0].upcase == location
      } rescue []


    t1 = Thread.new{
       Kernel.system "wkhtmltopdf -s A4 http://" +
          request.env["HTTP_HOST"] + "\"/patients/investigations_printable?patient_id=" +
          @patient.id.to_s + "&examination_number=#{ params["examination_number"] }&" +
          "encounter_date=#{ (params["encounter_date"] rescue "")}" +
          (params[:ret] ? "&ret=" + params[:ret] : "") + "&user_id=" + @user.to_s +
          "\" /tmp/output-" + @user.to_s + ".pdf \n"
      }

     t2 = Thread.new{
        sleep(5)
        Kernel.system "lp #{(!current_printer.blank? ? '-d ' + current_printer.to_s : "")} /tmp/output-" +
          @user.to_s + ".pdf\n"
      }

      t3 = Thread.new{

      sleep(10)
      Kernel.system "rm /tmp/output-" + @user.to_s + ".pdf\n"
      }

    end

    redirect_to "/patients/show?patient_id=#{@patient.id}&examination_number=#{ params["examination_number"] }&" +
          "encounter_date=#{ (params["encounter_date"] rescue "")}"+
      (params[:ret] ? "&ret=" + params[:ret] : "") and return
  end

  def visit_history
    session[:mastercard_ids] = []
    session_date = session[:datetime].to_date rescue Date.today
	  start_date = session_date.strftime('%Y-%m-%d 00:00:00')
	  end_date = session_date.strftime('%Y-%m-%d 23:59:59')
    if params[:examination_number]
      order = Order.find(:first, :conditions => ["accession_number = ?  AND voided = 0",params[:examination_number]])

      @encounters = Encounter.find(:all,:joins => "LEFT JOIN orders ON encounter.encounter_id = orders.encounter_id
      																							LEFT JOIN obs ON encounter.encounter_id = obs.encounter_id",
      															:conditions => ["orders.order_id = ? OR obs.order_id = ?", order.order_id, order.order_id],
                                   :group => ["encounter_id"],:order => "encounter_datetime DESC")
    else
      @encounters = Encounter.find(:all, :conditions => ["patient_id = ? AND encounter_datetime >= ? AND encounter_datetime <= ?",
                                                          @patient.id, start_date, end_date],:order => "encounter_datetime DESC")
    end

    @creator_name = {}
    @encounters.each do |encounter|
    	id = encounter.creator
			user_name = User.find(id).person.names.first
			@creator_name[id] = '(' + user_name.given_name.first + '. ' + user_name.family_name + ')'
    end

    @prescriptions = @patient.orders.unfinished.prescriptions.all
    @programs = @patient.patient_programs.all
    @alerts = alerts(@patient, session_date) rescue nil
    # This code is pretty hacky at the moment
    @restricted = ProgramLocationRestriction.all(:conditions => {:location_id => Location.current_health_center.id })
    @restricted.each do |restriction|
      @encounters = restriction.filter_encounters(@encounters)
      @prescriptions = restriction.filter_orders(@prescriptions)
      @programs = restriction.filter_programs(@programs)
    end

    render :template => 'dashboards/visit_history_tab', :layout => false
  end

  def mastercard_printable
    #the parameter are used to re-construct the url when the mastercard is called from a Data cleaning report
    @quarter = params[:quarter]
    @arv_start_number = params[:arv_start_number]
    @arv_end_number = params[:arv_end_number]
    @show_mastercard_counter = false

    if params[:patient_id].blank?

      @show_mastercard_counter = true

      if !params[:current].blank?
        session[:mastercard_counter] = params[:current].to_i - 1
      end

      @prev_button_class = "yellow"
      @next_button_class = "yellow"
      if params[:current].to_i ==  1
        @prev_button_class = "gray"
      elsif params[:current].to_i ==  session[:mastercard_ids].length
        @next_button_class = "gray"
      else

      end
      @patient_id = session[:mastercard_ids][session[:mastercard_counter]]
      @data_demo = mastercard_demographics(Patient.find(@patient_id))
      @visits = visits(Patient.find(@patient_id))
      #  @patient_art_start_date = PatientService.patient_art_start_date(@patient_id)
      #  elsif session[:mastercard_ids].length.to_i != 0
      #  @patient_id = params[:patient_id]
      #  @data_demo = mastercard_demographics(Patient.find(@patient_id))
      #  @visits = visits(Patient.find(@patient_id))
    else
      @patient_id = params[:patient_id]
      #@patient_art_start_date = PatientService.patient_art_start_date(@patient_id)
      @data_demo = mastercard_demographics(Patient.find(@patient_id))
      @visits = visits(Patient.find(@patient_id))
    end
    
    @visits.keys.each do|day|
		@age_in_months_for_days[day] = PatientService.age_in_months(@patient.person, day.to_date)
    end rescue nil

    render :layout => false
  end
end