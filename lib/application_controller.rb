# @deprecated - does this do anything useful?  If not, will be removed no later than 6.x release
module HydraHead
  ## Define ControllerMethods
  module Controller
  	## this one manages the usual self.included, klass_eval stuff
    extend ActiveSupport::Concern

    included do
      before_filter :method_for_before_filtering
    end

    def method_for_before_filtering
      #puts "Filtering before" 
    end

    def method_not_a_filter
      puts "not used as a filter"
    end
  end
end

#TODO this seems bad
::ActionController::Base.send :include, HydraHead::Controller


