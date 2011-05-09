class InvestigationController < ApplicationController
  def new
    @patient = Patient.find(params[:id])
  end

  def previous_investigations
   encounter_type = EncounterType.find_by_name('EXAMINATION').id
   @previous_investigations = Hash.new()
   Observation.find(:all,
    :joins => "INNER JOIN encounter e USING(encounter_id)",
    :conditions =>["patient_id = ? AND encounter_type = ?",
    params[:id],encounter_type]).map do | obs |
      name = obs_to = obs.to_s.split(':')[0]
      value = obs_to = obs.to_s.split(':')[1]
      next if name == 'WORKSTATION LOCATION'
      @previous_investigations[obs.obs_datetime.to_date] = {
                                                            'Investigation type' => nil,
                                                            'Xray type' => nil,
                                                            'Referred from' => nil,
                                                            'Payment method' => nil,
                                                            } if @previous_investigations[obs.obs_datetime.to_date].blank? 
      case  name
        when 'REFERRED BY'
          @previous_investigations[obs.obs_datetime.to_date]['Referred from'] = value
        when 'TYPE OF CARDIAC PROBLEM'
          @previous_investigations[obs.obs_datetime.to_date]['Investigation type'] = value
        when 'CHEST X-RAY OR CT SCAN CONSTRUCT'
          @previous_investigations[obs.obs_datetime.to_date]['Xray type'] = value
        when 'COST OF TRADITIONAL PRACTITIONER VISIT'
          @previous_investigations[obs.obs_datetime.to_date]['Payment method'] = value
      end                                                      
    end
    render :partial => 'previous_investigations' and return
  end

end
