class ClinicController < GenericClinicController

  def reports_tab
    @reports = [
      ["Film(s) used", "/people/films_used"],
      ["Examinations(Monthly)","/people/investigations"],
      ["Radiology Report","/people/radiology_report"]
    ]

    render :layout => false
  end

  def properties_tab
    @settings = []
    render :layout => false
  end
  
  def administration_tab
    @reports =  [
                  ['/clinic/users_tab','User Accounts/Settings'],
                  ['/clinic/location_management_tab','Location Management'],
                ]
    @landing_dashboard = 'clinic_administration'
    render :layout => false
  end

end
