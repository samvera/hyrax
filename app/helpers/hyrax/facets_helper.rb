# frozen_string_literal: true

module Hyrax
  module FacetsHelper
    # Methods in this module are from Blacklight::FacetsHelperBehavior, blacklight v6.24.0
    # This module is used to ensure Hyrax facet views that rely on deprecated Blacklight helper methods are still functional

    include Blacklight::Facet
  end
end
