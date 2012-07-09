class InvestigationController < ApplicationController
  def new
    @patient = Patient.find(params[:id])
  end
 
  def get_previous_encounters(patient_id)
     session_date = (session[:datetime].to_date rescue Date.today.to_date) - 1.days
     session_date = session_date.to_s + ' 23:59:59'
    previous_encounters = Encounter.find(:all,
              :conditions => ["encounter.voided = ? and patient_id = ? and encounter.encounter_datetime <= ?", 0, patient_id, session_date],
              :include => [:observations],:order => "encounter.encounter_datetime DESC"
            )
    return previous_encounters
  end
  
  def previous_investigations
    @previous_encounters  = get_previous_encounters(params[:id])
    @encounter_dates = @previous_encounters.map{|encounter| encounter.encounter_datetime.to_date}.uniq.first(6) rescue []
    @past_encounter_dates = @encounter_dates
     
    render :template => 'dashboards/past_visits_summary_tab', :layout => false
  end
end


