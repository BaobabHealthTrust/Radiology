class ReportController < GenericReportController

  def print_films_used
      @logo = CoreService.get_global_property_value("logo").to_s rescue ''
      @current_location_name = Location.current_health_center.name rescue ''
      @report_type = 'FILM USED'
      @month = (params[:month])
      @year = (params[:year])
  end

  def films_printable
      @logo = CoreService.get_global_property_value("logo").to_s rescue ''
      @current_location_name = Location.current_health_center.name rescue ''
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
     @logo = CoreService.get_global_property_value("logo").to_s rescue ''
     @current_location_name = Location.current_health_center.name rescue ''
     @month = (params[:month])
     @year = (params[:year])
     @investigation_type = (params[:investigation_type]) rescue ""
     @report_type = "INVESTIGATIONS"
  end

  def investigations_printable
    @logo = CoreService.get_global_property_value("logo").to_s rescue ''
    @current_location_name = Location.current_health_center.name rescue ''
    @month = (params[:month])
    @year = (params[:year])
    @investigation_type = (params[:investigation_type]) rescue ""
    case  @investigation_type.upcase
          when "XRAY"
            @investigation_options = ['Abdomen','Chest,xray','Ascending cysto-urethrography','Cystography',
																			'Cystogramurethrogram','Retrograde urography','Micturating Cysto-urethrography',
																			'Enema','Contrast Study Bronchogram','Contrast Study Hystero-Salpingogram','Contrast Study Sinogram',
                     								  'Contrast Study Sialogram','Lower limb','Pelvis girdle','Skull',
                                      'Spine','Upper limb','Meal','Meal follow-through','Swallow'].sort

          when "ULTRASOUND"
             @investigation_options = ['Abdomen,US','Carotid doppler','Contrast Echocardiography','Echocardiography,plain', 
																			'Female pelvis-gynaecology','Male pelvis','Musculoskeletal','Neonatal brain','Obstetric',
																			'Peripheral arterial and venous duplex','Stress Echocardiography','Superficial structures',
																			'Trans-vaginal','Trans-rectal','Ultrasound guided procedures'].sort

          when "MRI SCAN"
              @investigation_options = ['Abdomen, MR','Angiogram,MR','Brain','Cardiac','Pelvis'].sort
          when "COMPUTED TOMOGRAPHY SCAN"
              @investigation_options = ['Abdomen, CT','Cardiac','Chest routine','CT guided procedure',
                                        'Lower extremities, CT scan', 'Pelvis','Polytrauma','Brain','Upper extremities, CT scan',
																				'Virtual Colonoscopy','Trauma Head','Temporal Bone','Facial Bones','Sinuses','HRCT',
                                        'Pulmonary embolism','Cervical','Coccyx','Lumbar','Sacrum','Thoracic',
																				'Thoracico-Lumbar','Aorta','Carotid','Peripheral','Cerebral'].sort
          when "BONE DENSITOMETRY"
              @investigation_options = ['Bone densitometry']
          when "MAMMOGRAPHY"
             @investigation_options = ['Mammography']
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


        if @investigation_type.upcase == "COMPUTED TOMOGRAPHY SCAN"
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
     @logo = CoreService.get_global_property_value("logo").to_s rescue ''
     @current_location_name = Location.current_health_center.name rescue ''
     @report_type = 'RADIOLOGY'
     @start_date = params[:start_date]
     @end_date = params[:end_date]
     @daily_report = Report.daily_report(@start_date,@end_date)
  end

  def radiology_printable
     @logo = CoreService.get_global_property_value("logo").to_s rescue ''
     @current_location_name = Location.current_health_center.name rescue ''
     @start_date = params[:start_date]
     @end_date = params[:end_date]
     @daily_report = Report.daily_report(@start_date,@end_date)
     render :layout => false
  end

  def print_report
     @logo = CoreService.get_global_property_value("logo").to_s rescue ''
     @current_location_name = Location.current_health_center.name rescue ''
     app_url = CoreService.get_global_property_value('app.url')
     url = ''
     case params['report_type'].upcase
         when 'FILM USED'
            url = "http://radiology/report/films_printable?month=#{ params['month']}&year=#{ params['year']}"
         when 'INVESTIGATIONS'
            url = "http://radiology/report/investigations_printable?month=#{ params['month']}&year=#{ params['year']}&investigation_type=#{ params['investigation_type']}"
         when 'RADIOLOGY'
            url = "http://radiology/report/radiology_printable?start_date=#{ params['start_date']}&end_date=#{ params['end_date']}"
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
