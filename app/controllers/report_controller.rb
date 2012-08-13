class ReportController < GenericReportController

  def show 
    @month = (params[:month])
    @year = (params[:year])
    @investigation_type = (params[:investigation_type]) rescue ""
    
    case params[:id]
      when 'film_used'
        @report_type = 'FILM SIZE'
        @film_size_options = ['18x24','18x43','24x30','30x40','35x35','35x43']
        @aggregates = Report.film_used(ConceptName.find_by_name("GOOD FILM").concept_id,@month.to_i,@year.to_i)
        @wasted_film = Report.film_used(ConceptName.find_by_name("WASTED FILM").concept_id,@month.to_i,@year.to_i)
        start_date = "#1-#{@month.to_i}-#{@year.to_i}".to_date.strftime("%Y-%m-%d 00:00:00")
        end_date = "#{Time.days_in_month(@month.to_i)}-#{@month.to_i}-#{@year.to_i}".to_date.strftime("%Y-%m-%d 23:59:59")
        @revenue_collected = Report.revenue_collected(start_date,end_date)
      when 'investigations'
        @report_type = "INVESTIGATIONS"
        case  @investigation_type.upcase
          when "XRAY"
            @investigation_options = ['Skull','Chest','Upper Limb','Lower Limb','Stenum/Rib/Shoulder','Abdomen',
                      'Spine','Pelvis','Contrast GI Studies','Contrast UT Studies','Hystero-Salpingogram',
                      'Mammography','Sinogram','Siologram','Bronchogram']

          when "ULTRASOUND"
             @investigation_options = ['Breast','Musculoskeletal','Carotid Doppler','Abdominal Doppler and Color Flow',
                            'Male Pelvis - Prostate Gland, Scrotum and Penis','Thyroid and Parathyroid Glands',
                            'Peritheral Arterial and Venous Duplex','Abdomen','Obsterics-Fetal','Female Pelvis-Gynaecology',
                            'Echocardiography-Adult','Echochardiography-Pediatric','Neonatal Brain','Transvaginal','Transrectal',
                            'Prostate','FAST','Umbilical Artery Doppler','Ultrasound Guided Procedures']

          when "MRI"
              @investigation_options = ['Brain','Chest','Abdomen','Pelvis','Angiogram','Upper Extremity','Lower Extremity']
          when "CT"
              @investigation_options = ['Brain','Chest','Abdomen','Pelvis','Angiogram','Upper Extremity','Lower Extremity']
         end
         @aggregates = Report.investigations(@investigation_type,@month.to_i,@year.to_i)
         
           
    end
    render :layout => 'menu'
  end
   
end
