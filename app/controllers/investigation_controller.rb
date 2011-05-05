class InvestigationController < ApplicationController
  def new
    @patient = Patient.find(params[:id])
  end

end
