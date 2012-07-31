class ReportController < GenericReportController

  def examination
    @patient = Patient.find(params[:id])                                        
    encounter_type = EncounterType.find_by_name('OBSERVATIONS').id              
    @examinations = Hash.new()                                                  
    Observation.find(:all,                                                      
      :joins => "INNER JOIN encounter e USING(encounter_id)",                   
      :conditions =>["patient_id = ? AND encounter_type = ?",                   
      params[:id],encounter_type]).map do | obs |                               
        name = obs_to = obs.to_s.split(':')[0]                                  
        value = obs_to = obs.to_s.split(':')[1]                                 
        next if name.match(/WORKSTATION LOCATION/i)                                 
        @examinations[obs.obs_datetime.to_date] = nil if @examinations[obs.obs_datetime.to_date].blank?
        @examinations[obs.obs_datetime.to_date] += '<br />' + obs.value_text unless  @examinations[obs.obs_datetime.to_date].blank?
        @examinations[obs.obs_datetime.to_date] = obs.value_text if  @examinations[obs.obs_datetime.to_date].blank?
    end                                                                         
    render :partial => 'examination' and return                                 
  end

  def show 
    @start_date = (params[:start_date]).to_date
    @end_date = (params[:end_date]).to_date
    case params[:id]
      when 'film_used'
        @xray = 'FILM SIZE'
        @encounters = Report.film_used(@start_date,@end_date) 
      when 'investigations'
        @xray = 'EXAMINATION'
        @encounters = Report.investigations(@start_date,@end_date)
    end
    render :layout => 'menu'
  end
   
end
