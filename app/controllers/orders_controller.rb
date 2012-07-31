class OrdersController < ApplicationController
  def new

  end

  def create

    @patient = Patient.find(params[:encounter][:patient_id] || session[:patient_id]) rescue nil
    unless params[:location]
      session_date = session[:datetime] || Time.now()
    else
      session_date = params[:encounter_datetime] #Use date_created passed during import
    end



    # set current location via params if given
    Location.current_location = Location.find(params[:location]) if params[:location]

    if params[:filter] and !params[:filter][:provider].blank?

      user_person_id = User.find_by_username(params[:filter][:provider]).person_id
    elsif params[:location]
      user_person_id = params[:provider_id]
    else
      user_person_id = current_user.person_id
    end

    encounter_type_name = params[:encounter][:encounter_type_name]
    @encounter = current_encounter(encounter_type_name,@patient, session_date, user_person_id)
    examination_number = params['examination_number']
    if params['investigation_type']
      order_type_name = params['investigation_type']
      concept = ConceptName.find_by_name(params['investigation_type_value'])
      @order = current_order(examination_number,@patient,order_type_name,concept,@encounter.encounter_id)
    else
      @order = current_order(examination_number,@patient)
    end
    
    @order_id = @order.order_id

    params['observations'].each do |ob|
      if ob['value_coded'].blank? && ob['value_coded_or_text'].blank?
        obs = Observation.new(
          :concept_name => ob['concept_name'],
          :order_id => @order_id,
          :value_text =>ob['value_text'],
          :person_id => @patient.person.person_id,
          :encounter_id => @encounter.id,
          :obs_datetime => session_date || Time.now())
      obs.save
      else
        obs = Observation.new(
            :concept_name => ob['concept_name'],
            :order_id => @order_id,
            :value_coded =>ob['value_coded'],
            :value_text =>ob['value_coded_or_text'],
            :person_id => @patient.person.person_id,
            :encounter_id => @encounter.id,
            :obs_datetime => session_date || Time.now())
        obs.save
      end
    end

    redirect_to :controller => :patients ,:action => :show ,:id => @patient.patient_id

  end


  def current_encounter(encounter_type_name,patient, date = Time.now(), provider = current_user.person_id)
    type = EncounterType.find_by_name(encounter_type_name)
    encounter = patient.encounters.find(:first,:conditions =>["DATE(encounter_datetime) = ? AND encounter_type = ?",date.to_date,type.id])
    encounter ||= patient.encounters.create(:encounter_type => type.id,:encounter_datetime => date, :provider_id => provider)
  end

  
  def current_order(examination_number,patient,order_type_name = nil, concept = nil,encounter_id = nil ,provider = current_user.person_id)

    type = OrderType.find_by_name(order_type_name)
    order = patient.orders.find_by_accession_number(examination_number)
    order ||= patient.orders.create(:order_type_id => type.id,
                                    :patient_id => patient.patient_id,
                                    :concept_id => concept.concept_id,
                                    :encounter_id => encounter_id,
                                    :orderer => provider,
                                    :accession_number => examination_number)
  end


end
