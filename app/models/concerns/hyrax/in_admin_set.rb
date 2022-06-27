# frozen_string_literal: true
module Hyrax
  module InAdminSet
    extend ActiveSupport::Concern

    included do
      belongs_to :admin_set, predicate: Hyrax.config.admin_set_predicate
    end
  end
end
