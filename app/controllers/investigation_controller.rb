class InvestigationController < ApplicationController
  def new
    @patient = Patient.find(params[:id])
    radiology_tests_id = ConceptName.find_by_name("LIST OF RADIOLOGY TESTS").concept_id
    @examination_sets = ConceptSet.find( :all,
                                          :select => "DISTINCT concept_set",
                                          :conditions => ["concept_set IN (SELECT concept_id FROM concept_set
                                            WHERE concept_set IN (SELECT concept_id FROM concept_set WHERE concept_set = ?))",
                                            radiology_tests_id]).map{ | item |
                                              next if item.concept_set.blank?
                                              Concept.find(item.concept_set).fullname
                                            }.join(';')
    @referral_locations = CoreService.get_global_property_value("radiology.referral.locations").split(';')
  end

  def radiology_list(concept_name)
    concept_id = concept_id = ConceptName.find_by_name(concept_name).concept_id
    set = ConceptSet.find_all_by_concept_set(concept_id, :order => 'sort_weight')
    options = set.map{|item|next if item.concept.blank? ; [item.concept.fullname] }
  end

  def examination
				concept_name = params[:examination_type]
        concept_id = concept_id = ConceptName.find_by_name(concept_name).concept_id
        set = ConceptSet.find_all_by_concept_set(concept_id, :order => 'sort_weight')
        options = set.map{|item|next if item.concept.blank? ; [item.concept.fullname] }
		    render :text => "<li></li><li>" + options.join("</li><li>") + "</li>"
  end

  def location_wards
    wards = Location.find_by_sql("SELECT l.* FROM location l
                                  INNER JOIN location_tag_map ltm
                                  ON l.location_id = ltm.location_id
                                  INNER JOIN location_tag lt
                                  ON lt.location_tag_id = ltm.location_tag_id
                                  WHERE lt.name = 'Ward'")
    wards.map do |ward|
       [ward.name, ward.location_id]
    end

  end
 
end


