module Hyrax
  module DashboardHelperBehavior
    def on_the_dashboard?
      params[:controller].match(%r{^hyrax/dashboard|hyrax/my})
    end

    def on_my_works?
      params[:controller].match(%r{^hyrax/my/works})
    end

    def number_of_works(user = current_user)
      Hyrax::Statistics::Depositors::Depositor.works(depositor: user)
    end

    def number_of_files(user = current_user)
      Hyrax::Statistics::Depositors::Depositor.file_sets(depositor: user)
    end

    def number_of_collections(user = current_user)
      Hyrax::Statistics::Depositors::Depositor.collections(depositor: user)
    end
  end
end
