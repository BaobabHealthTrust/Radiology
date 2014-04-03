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

  def examination
				examination = params[:examination]
        condition = ""

				concept_name = params[:radiology_test]
        concept_id = ConceptName.find_by_name(concept_name).concept_id rescue nil

        if examination.blank?
          condition = "concept_set = #{concept_id}"
        else
          examination = "%" + examination + "%"
          condition = "concept_set = #{concept_id} AND concept_name.name LIKE '#{examination}'"
        end

				concept_name = params[:examination]
        concept_id = ConceptName.find_by_name(concept_name).concept_id rescue nil
        set = ConceptSet.find(:all, :joins => 'LEFT JOIN concept_name ON concept_set.concept_id = concept_name.concept_id', 
          :conditions => condition, :group => "concept_id", :order => 'sort_weight')
        options = set.map{|item|next if item.concept.blank? ; [item.concept.fullname] }
		    render :text => "<li></li><li>" + options.join("</li><li>") + "</li>"
  end

  def detailed_examination
				concept_name = params[:detailed_examination]
        concept_id = ConceptName.find_by_name(concept_name).concept_id rescue nil
        set = ConceptSet.find_all_by_concept_set(concept_id, :order => 'sort_weight')
        options = set.map{|item|next if item.concept.blank? ; [item.concept.fullname] }
		    render :text => "<li></li><li>" + options.join("</li><li>") + "</li>"
  end
end


