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
    @encounter = create_encounter(encounter_type_name,@patient, session_date, user_person_id)
    examination_number = params['examination_number']
    if params['investigation_type']
      order_type_name = params['investigation_type']

      if params['xray_investigation_value'] !=""
        concept = ConceptName.find_by_name(params['xray_investigation_value'])
      elsif params['ultrasound_investigation_value'] !=""
        concept = ConceptName.find_by_name(params['ultrasound_investigation_value'])
      elsif params['mri_investigation_value'] !=""
        concept = ConceptName.find_by_name(params['mri_investigation_value'])
      elsif params['ct_investigation_value'] !=""
        concept = ConceptName.find_by_name(params['ct_investigation_value'])
      end

      @order = current_order(examination_number,@patient,order_type_name,concept,@encounter.encounter_id)
    else
      @order = current_order(examination_number,@patient)
    end
    
    @order_id = @order.order_id

    params['observations'].each do |ob|
     if ob['concept_name'] == "FILM SIZE"
       @film_size = ob['value_coded_or_text']
     elsif ob['concept_name'] == "GOOD FILM" || ob['concept_name'] == "WASTED FILM"
       @available_film = ob['value_coded_or_text']
     end
    end

    if encounter_type_name == "FILM"
       params['observations'].each do |ob|

      if  ob['concept_name'] == "GOOD FILM" || ob['concept_name'] == "WASTED FILM"
       
      1.upto(ob['value_coded_or_text'].to_i) do
          obs = Observation.new(
            :concept_name => ob['concept_name'],
            :order_id => @order_id,
            :value_text =>@film_size,
            :person_id => @patient.person.person_id,
            :encounter_id => @encounter.id,
            :obs_datetime => session_date || Time.now())
      obs.save
      end
      elsif !@available_film.blank?
        
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
    else

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
    end

    if encounter_type_name == "EXAMINATION"
         print_and_redirect("/orders/examination_number?order_id=#{@order_id}", "/clinic")
    else
         redirect_to :controller => :patients ,:action => :show ,:id => @patient.patient_id
    end

  end
  
  def examination_number
    print_string = PatientService.examination_number_label(params[:order_id])
    send_data(print_string,:type=>"application/label; charset=utf-8",:stream=> false, 
      :filename=>"#{params[:order_id]}#{rand(10000)}.lbl",:disposition => "inline")
  end

  def create_encounter(encounter_type_name,patient, date = Time.now(), provider = current_user.person_id)
    type = EncounterType.find_by_name(encounter_type_name)
    encounter = patient.encounters.create(:encounter_type => type.id,:encounter_datetime => date, :provider_id => provider)
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
