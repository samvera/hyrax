# frozen_string_literal: true
module Hyrax
  module BasicMetadataFormFieldsBehavior
  extend ActiveSupport::Concern

  included do
    include Hyrax::BasedNearFieldBehavior
  end
 end
end
