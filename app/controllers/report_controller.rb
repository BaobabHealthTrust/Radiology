class ReportController < GenericReportController

  def show 
    @month = (params[:month])
    @year = (params[:year])
    @investigation_type = (params[:investigation_type]) rescue ""
    
    case params[:id]
      when 'film_used'
        @report_type = 'FILM SIZE'
        @encounters = Report.film_used(@start_date,@end_date) 
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
         when 'revenue_collected'
           
    end
    render :layout => 'menu'
  end
   
end
