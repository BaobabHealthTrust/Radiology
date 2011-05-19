class ClinicController < ApplicationController
  def index
=begin
    @types = GlobalProperty.find_by_property("statistics.show_encounter_types").property_value rescue EncounterType.all.map(&:name).join(",")
    @types = @types.split(/,/)
    @me = Encounter.statistics(@types, :conditions => ['DATE(encounter_datetime) = DATE(NOW()) AND encounter.creator = ?', User.current_user.user_id])
    @today = Encounter.statistics(@types, :conditions => ['DATE(encounter_datetime) = DATE(NOW())'])
    @year = Encounter.statistics(@types, :conditions => ['YEAR(encounter_datetime) = YEAR(NOW())'])
    @ever = Encounter.statistics(@types)
=end
    render :template => 'clinic/home', :layout => 'dashboard' 
  end

  def overview
    @types = GlobalProperty.find_by_property("statistics.show_encounter_types").property_value rescue EncounterType.all.map(&:name).join(",")
    @types = @types.split(/,/)
    @me = Encounter.statistics(@types, :conditions => ['DATE(encounter_datetime) = DATE(NOW()) AND encounter.creator = ?', User.current_user.user_id])
    @today = Encounter.statistics(@types, :conditions => ['DATE(encounter_datetime) = DATE(NOW())'])
    @year = Encounter.statistics(@types, :conditions => ['YEAR(encounter_datetime) = YEAR(NOW())'])
    @ever = Encounter.statistics(@types)
  end

  def reports
    @reports = [
                ["Overview","/people/date_select?id=overview"],
                ["Film(s) used","/people/date_select?id=film_used"], 
                ["Investigations", "/people/date_select?id=investigations"]
              ]
    render :template => 'clinic/reports', :layout => 'clinic' 
  end

  def supervision
    @supervision_tools = [["Data that was Updated","summary_of_records_that_were_updated"],
                          ["Drug Adherence Level","adherence_histogram_for_all_patients_in_the_quarter"],
                          ["Visits by Day", "visits_by_day"],
                          ["Non-eligible Patients in Cohort", "non_eligible_patients_in_cohort"]]

   @landing_dashboard = 'clinic_supervision'

    render :template => 'clinic/supervision', :layout => 'clinic' 
  end

  def properties
    @settings = [
                  ["Set clinic days","/properties/clinic_days"],
                  ["View clinic holidays","/properties/clinic_holidays"],
                  ["Set clinic holidays","/properties/set_clinic_holidays"], 
                  ["Set site code", "/properties/site_code"],
                  ["Set appointment limit", "/properties/set_appointment_limit"]
                ]
    render :template => 'clinic/properties', :layout => 'clinic' 
  end

  def printing
    render :template => 'clinic/printing', :layout => 'clinic' 
  end

  def users
    #render :template => 'clinic/users', :layout => 'clinic' 
  end

  def administration
    @reports = [['/clinic/users','User accounts/settings']]
    @landing_dashboard = 'clinic_administration'
    render :template => 'clinic/administration', :layout => 'clinic' 
  end

end
