class ClinicController < GenericClinicController

  def reports_tab
    @reports = [
      ["Investigations","/people/date_select?id=investigations"],
      ["Film(s) used", "/people/date_select?id=film_used"]
    ]

    render :layout => false
  end

  def properties_tab
    @settings = [
      ["Manage Roles", "/properties/set_role_privileges"]
    ]
    render :layout => false
  end

end
