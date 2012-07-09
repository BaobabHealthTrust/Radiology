class PatientsController < GenericPatientsController

  def show
    session[:mastercard_ids] = []
    session_date = session[:datetime].to_date rescue Date.today

		@patient_bean = PatientService.get_patient(@patient.person)
		@encounters = @patient.encounters.find_by_date(session_date)

    @show_investigation = Encounter.find(:first,:order => "encounter_datetime DESC",:conditions =>["encounter_type = ? AND patient_id = ? AND DATE(encounter_datetime) = ?",EncounterType.find_by_name("EXAMINATION").id,@patient.id,session_date]) == nil

    @date = session_date.strftime("%Y-%m-%d")

    @location = Location.find(session[:location_id]).name rescue ""
   
    if @location.downcase == "outpatient" || params[:source]== 'opd'
      render :template => 'dashboards/opdtreatment_dashboard', :layout => false
    else
      render :template => 'patients/index', :layout => false  
    end
  end
  
  def overview
    @patient = Patient.find(params[:id])
    @encounter_date = session[:datetime].to_date rescue Date.today
    encounter_types = EncounterType.find(:all,:conditions =>["name IN (?)",['EXAMINATION','FILM SIZE']])
    @encounters = Encounter.find(:all,:conditions =>["encounter_type IN (?) AND patient_id = ? AND DATE(encounter_datetime)=?",
                                 encounter_types.collect{|e|e.id},@patient.id,@encounter_date])
    render :template => 'dashboards/overview_tab', :layout => false  
  end
  
  def examination                                                               
    @patient = Patient.find(params[:id])                                        
    @encounter_date = session[:datetime].to_date rescue Date.today                                
  end  
   
end
