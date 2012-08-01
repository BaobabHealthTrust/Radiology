class PatientsController < GenericPatientsController
 
  def personal
    @links = []
    patient = Patient.find(params[:id])
    
    if use_user_selected_activities
      @links << ["Change User Activities","/user/activities/#{current_user.id}?patient_id=#{patient.id}"]
    end
    @links << ["National ID (Print)","/patients/dashboard_print_national_id/#{patient.id}"]
    @links << ["Investigation (Print)","/patients/dashboard_print_visit/#{patient.id}"]
    
    render :template => 'dashboards/personal_tab', :layout => false
  end
  
  def patient_visit_label(patient, date = Date.today)
      label = ZebraPrinter::StandardLabel.new
      label.font_size = 3
      label.font_horizontal_multiplier = 1
      label.font_vertical_multiplier = 1
      label.left_margin = 50
      encs = patient.encounters.find(:all,:conditions =>["DATE(encounter_datetime) = ?",date])
      return nil if encs.blank?

      label.draw_multi_text("Investigation: #{encs.first.encounter_datetime.strftime("%d/%b/%Y %H:%M")}", :font_reverse => true)
      encs.each {|encounter|
        encounter.to_s.split("<b>").each do |string|
          concept_name = string.split("</b>:")[0].strip rescue nil
          obs_value = string.split("</b>:")[1].strip rescue nil
          next if string.match(/Workstation location/i)
          next if obs_value.blank?
          label.draw_multi_text("#{encounter.name.humanize} - #{concept_name}: #{obs_value}", :font_reverse => false)
        end
      }
      label.print(1)
    end

  def examination
    exam_number = params[:examination_number]
    @order = Order.find(:first,:conditions => ["accession_number = ? AND voided = 0",exam_number])
    @patient = Patient.find(@order.patient_id)
    @encounter_date = params[:encounter_date]
  end

  def visit_history
    session[:mastercard_ids] = []
    session_date = session[:datetime].to_date rescue Date.today
	  start_date = session_date.strftime('%Y-%m-%d 00:00:00')
	  end_date = session_date.strftime('%Y-%m-%d 23:59:59')
    if params[:examination_number]
      @encounters = Encounter.find(:all,:joins => :orders,:conditions => ["accession_number = ? ",params[:examination_number]])
    else
      @encounters = Encounter.find(:all, 	:conditions => [" patient_id = ? AND encounter_datetime >= ? AND encounter_datetime <= ?", @patient.id, start_date, end_date])
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


end
  
