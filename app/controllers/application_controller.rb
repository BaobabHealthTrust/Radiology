class ApplicationController < GenericApplicationController  

  def next_form(location , patient , session_date = Date.today)
    #for Radiology department we do not need auto form select
    task = Task.first rescue Task.new()
    task.encounter_type = nil
    task.url = "/patients/show/#{patient.id}"
    return task
  end

  # Try to find the next task for the patient at the given location
  def main_next_task(location, patient, session_date = Date.today)
    if use_user_selected_activities
      return next_form(location , patient , session_date)
    end

    #for Radiology department we do not need auto form select
    task = Task.first rescue Task.new()
    task.encounter_type = nil
    task.url = "/patients/show/#{patient.id}"
    return task
  end
 
end
