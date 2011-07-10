module ReleaseProcessHelper
  
  def display_release_status_notice(document)
    readiness = document.test_release_readiness
    if readiness == true
      flash[:notice] ||= []
      if document.submitted_for_release?
        flash[:notice] << "This item has been released for library circulation."
      else
        flash[:notice] << "This item is ready to be released for library circulation."
      end
    else
      flash[:error] ||= []
      flash[:error] = flash[:error] | readiness[:failures]
    end
  end

  def check_embargo_date_format
    if params.keys.include? [:embargo, :embargo_release_date]
      em_date = params[[:embargo, :embargo_release_date]]["0"]
      unless em_date.blank?
        begin 
          !Date.parse(em_date)
        rescue
          params[[:embargo,:embargo_release_date]]["0"] = ""
          raise "Unacceptable date format"
        end
      end
    end
  end  
  
end