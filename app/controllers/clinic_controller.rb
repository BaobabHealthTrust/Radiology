class ClinicController < GenericClinicController

  def reports_tab
    @reports = [
      ["Revenue", "/people/date_select?id=revenue_collected"],
      ["Film(s) used", "/people/date_select?id=film_used"],
      ["Investigations","/people/date_select?id=investigations"]
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
