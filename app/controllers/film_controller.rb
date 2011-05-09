class FilmController < ApplicationController
  def size
    @patient = Patient.find(params[:id])
  end

  def previous_films
   encounter_type = EncounterType.find_by_name('LAB').id
   @previous_films = Hash.new()
   Observation.find(:all,
    :joins => "INNER JOIN encounter e USING(encounter_id)",
    :conditions =>["patient_id = ? AND encounter_type = ?",
    params[:id],encounter_type]).map do | obs |
      name = obs_to = obs.to_s.split(':')[0]
      value = obs_to = obs.to_s.split(':')[1]
      next if name == 'WORKSTATION LOCATION'
      @previous_films[obs.obs_datetime.to_date] = {
                                                    'Size' => nil,
                                                    'Bad film' => nil,
                                                    'Good film' => nil,
                                                  } if @previous_films[obs.obs_datetime.to_date].blank? 

      case  name
        when 'SIZE OF VENTRICULAR SEPTAL DEFECT'
          @previous_films[obs.obs_datetime.to_date]['Size'] = value
        when 'REFERRED BY'
          @previous_films[obs.obs_datetime.to_date]['Bad film'] = value
        when 'REFERRED'
          @previous_films[obs.obs_datetime.to_date]['Good film'] = value
      end                                                      
    end
    render :partial => 'previous_films' and return
  end

end
