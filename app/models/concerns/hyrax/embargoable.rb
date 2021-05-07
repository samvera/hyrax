# frozen_string_literal: true
module Hyrax
  module Embargoable
    extend ActiveSupport::Concern
    include Hydra::AccessControls::Embargoable

    included do
      validates :lease_expiration_date, 'hydra/future_date': true, on: :create
      validates :embargo_release_date, 'hydra/future_date': true, on: :create
    end

    ##
    # Override aggressive Hydra::AccessControls validation
    def enforce_future_date_for_embargo?
      false
    end

    ##
    # Override aggressive Hydra::AccessControls validation
    def enforce_future_date_for_lease?
      false
    end
  end
end
