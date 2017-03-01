module Hyrax
  module DashboardHelperBehavior
    def on_the_dashboard?
      params[:controller].match(%r{^hyrax/dashboard|hyrax/my})
    end

    def on_my_works?
      params[:controller].match(%r{^hyrax/my/works})
    end

    def number_of_works(user = current_user)
      Hyrax::WorkRelation.new.where(DepositSearchBuilder.depositor_field => user.user_key).count
    rescue RSolr::Error::ConnectionRefused
      'n/a'
    end

    def number_of_files(user = current_user)
      ::FileSet.where(DepositSearchBuilder.depositor_field => user.user_key).count
    rescue RSolr::Error::ConnectionRefused
      'n/a'
    end

    def number_of_collections(user = current_user)
      ::Collection.where(DepositSearchBuilder.depositor_field => user.user_key).count
    rescue RSolr::Error::ConnectionRefused
      'n/a'
    end
  end
end
