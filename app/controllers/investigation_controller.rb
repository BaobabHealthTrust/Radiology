class InvestigationController < ApplicationController
  def new
    @patient = Patient.find(params[:id])
    @next_exam_number = next_available_exam_number
    @wards = location_wards
  end
 
  def next_available_exam_number                                           
    prefix = 'R'                                                                
    last_exam_num = Order.find(:first, :order => "accession_number DESC",
                   :conditions => ["voided = 0"]
                   ).accession_number rescue []
                                                                                
    index = 0                                                                   
    last_exam_num.each_char do | c |                                            
      next if c == prefix                                                       
      break unless c == '0'                                                     
      index+=1                                                                  
    end unless last_exam_num.blank?                                             
                                                                                
    last_exam_num = '0' if last_exam_num.blank?                                 
    prefix + (last_exam_num[index..-1].to_i + 1).to_s.rjust(8,'0')              
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


