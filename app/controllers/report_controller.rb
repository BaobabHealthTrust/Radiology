class ReportController < GenericReportController

  def print_films_used
      @report_type = 'FILM USED'
      @month = (params[:month])
      @year = (params[:year])
  end

  def films_printable
      @month = (params[:month])
      @year = (params[:year])
      @film_size_options = ['13 x 18 cm','18 x 24 cm','18 x 43 cm','24 x 30 cm','30 x 40 cm','35 x 35 cm','35 x 43 cm']
      @aggregates = Report.film_used(ConceptName.find_by_name("GOOD FILM").concept_id,@month.to_i,@year.to_i)
      @wasted_film = Report.film_used(ConceptName.find_by_name("WASTED FILM").concept_id,@month.to_i,@year.to_i)
      start_date = "#1-#{@month.to_i}-#{@year.to_i}".to_date.strftime("%Y-%m-%d 00:00:00")
      end_date = "#{Time.days_in_month(@month.to_i)}-#{@month.to_i}-#{@year.to_i}".to_date.strftime("%Y-%m-%d 23:59:59")
      @revenue_collected = Report.revenue_collected(start_date,end_date)
      render :layout => false
  end

  def print_investigation
     @month = (params[:month])
     @year = (params[:year])
     @investigation_type = (params[:investigation_type]) rescue ""
     @report_type = "INVESTIGATIONS"
  end

  def investigations_printable
    @month = (params[:month])
    @year = (params[:year])
    @investigation_type = (params[:investigation_type]) rescue ""
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
    render :layout => false
  end

  def print_radiology_report
     @report_type = 'RADIOLOGY'
     @start_date = params[:start_date]
     @end_date = params[:end_date]
     @daily_report = Report.daily_report(@start_date,@end_date)
  end

  def radiology_printable
     @start_date = params[:start_date]
     @end_date = params[:end_date]
     @daily_report = Report.daily_report(@start_date,@end_date)
     render :layout => false
  end

  def print_report
     app_url = CoreService.get_global_property_value('app.url')
     url = ''
     case params['report_type'].upcase
         when 'FILM USED'
            url = "http://#{app_url}/report/films_printable?month=#{ params['month']}&year=#{ params['year']}"
         when 'INVESTIGATIONS'
            url = "http://#{app_url}/report/investigations_printable?month=#{ params['month']}&year=#{ params['year']}&investigation_type=#{ params['investigation_type']}"
         when 'RADIOLOGY'
            url = "http://#{app_url}/report/radiology_printable?start_date=#{ params['start_date']}&end_date=#{ params['end_date']}"
     end
  
     response = RestClient.get(url)
     pages = PDFKit.new(response, :page_size => 'A4')
     send_data(pages.to_pdf,:type=>"application/label; charset=utf-8",:stream=> false,
      :filename=>"#{params[:month]}#{params[:year]}#{rand(10000)}.pdf",:disposition => "inline")
  end

  def report_print
    print_and_redirect("/report/print_report?month=#{ params['month']}&year=#{ params['year']}&start_date=#{ params['start_date']}&end_date=#{ params['end_date']}&report_type=#{ params['report_type']}&investigation_type=#{ params['investigation_type']}", "/clinic")  
  end
  
  private
  def concept_set_options(concept_name)
    concept_id = concept_id = ConceptName.find_by_name(concept_name).concept_id
    set = ConceptSet.find_all_by_concept_set(concept_id, :order => 'sort_weight')
    options = set.map{|item|next if item.concept.blank? ; [item.concept.fullname] }
  end
   
end