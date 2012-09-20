class ReportController < GenericReportController

  def show
    @month = (params[:month])
    @year = (params[:year])
    @investigation_type = (params[:investigation_type]) rescue ""
    
    case params[:id]
      when 'film_used'
        @report_type = 'FILM SIZE'
        @film_size_options = ['13 x 18 cm','18 x 24 cm','18 x 43 cm','24 x 30 cm','30 x 40 cm','35 x 35 cm','35 x 43 cm']
        @aggregates = Report.film_used(ConceptName.find_by_name("GOOD FILM").concept_id,@month.to_i,@year.to_i)
        @wasted_film = Report.film_used(ConceptName.find_by_name("WASTED FILM").concept_id,@month.to_i,@year.to_i)
        start_date = "#1-#{@month.to_i}-#{@year.to_i}".to_date.strftime("%Y-%m-%d 00:00:00")
        end_date = "#{Time.days_in_month(@month.to_i)}-#{@month.to_i}-#{@year.to_i}".to_date.strftime("%Y-%m-%d 23:59:59")
        @revenue_collected = Report.revenue_collected(start_date,end_date)
      when 'investigations'
        @report_type = "INVESTIGATIONS"
        case  @investigation_type.upcase
          when "XRAY"
            @investigation_options = ['Skull','Chest','Upper limb','Lower limb','Stenum','Shoulder exam','Abdomen',
                      'Spine','Pelvis','Contrast UT studies','HSG',
                      'Mammography','Sinogram','Sialogram','Bronchogram','Enema','Swallow','Meal'].sort

          when "ULTRASOUND"
             @investigation_options = ['Breast','Musculoskeletal','Carotid doppler','Abdominal doppler and color flow',
                            'Prostate gland, scrotum and penis','Thyroid and parathyroid glands',
                            'Peritheral arterial and venous duplex','Abdomen','Obsterics,fetal','Female pelvis, gynaecology',
                            'Echocardiography','Neonatal brain','Transvaginal','Transrectal',
                            'Prostate','Focussed assessment with sonography in trauma','Umbilical artery doppler','Ultrasound guided procedures'].sort

          when "MRI SCAN"
              @investigation_options = ['Brain','Chest','Abdomen','Pelvis','Angiogram','Upper extremities, MRI scan','Lower extremities, MRI scan'].sort
          when "COMPUTED TOMOGRAPHY SCAN"
              @investigation_options = ['Brain','Chest','Abdomen','Pelvis','Angiogram','Upper extrimities, CT scan','Lower extremities, CT scan'].sort
         end
         if @investigation_type.upcase == "XRAY"
             aggregated = Report.investigations(@investigation_type,@month.to_i,@year.to_i)
             aggregates_detailed =  Report.detailed_investigations(@investigation_type,@month.to_i,@year.to_i)
             aggregating = aggregated.merge(aggregates_detailed){|key,oldval,newval| [*oldval] + [*newval] }
             @aggregates = Hash.new()
             aggregating.each do|key,examination|
               @aggregates[key] = Hash.new()
                unless examination.blank?
                  examination.each do |exam|
                    unless exam.blank?
                     @aggregates[key][exam[0]] = exam[1]
                    end
                  end
                end
             end
         else
            @aggregates = Report.investigations(@investigation_type,@month.to_i,@year.to_i)
         end
     when 'investigations_daily'
           @report_type = 'INVESTIGATIONS_DAILY'
           @start_date = params[:start_date]
           @end_date = params[:end_date]
           @daily_report = Report.daily_report(@start_date,@end_date)
    end
    render :layout => 'reports'
  end

  private
  def concept_set_options(concept_name)
    concept_id = concept_id = ConceptName.find_by_name(concept_name).concept_id
    set = ConceptSet.find_all_by_concept_set(concept_id, :order => 'sort_weight')
    options = set.map{|item|next if item.concept.blank? ; [item.concept.fullname] }
  end
   
end