class FilmController < ApplicationController
  def size
    @patient = Patient.find(params[:id])
  end

end
