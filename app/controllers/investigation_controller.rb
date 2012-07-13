class InvestigationController < ApplicationController
  def new
    @patient = Patient.find(params[:id])
    @next_exam_number = next_available_exam_number
  end
 
  def next_available_exam_number                                           
    prefix = 'R'                                                                
    last_exam_num = Observation.find(:first, :order => "value_text DESC",       
                   :conditions => ["concept_id = ?",
                    ConceptName.find_by_name('EXAMINATION NUMBER').concept_id]
                   ).value_text rescue []
                                                                                
    index = 0                                                                   
    last_exam_num.each_char do | c |                                            
      next if c == prefix                                                       
      break unless c == '0'                                                     
      index+=1                                                                  
    end unless last_exam_num.blank?                                             
                                                                                
    last_exam_num = '0' if last_exam_num.blank?                                 
    prefix + (last_exam_num[index..-1].to_i + 1).to_s.rjust(8,'0')              
  end
 
end


