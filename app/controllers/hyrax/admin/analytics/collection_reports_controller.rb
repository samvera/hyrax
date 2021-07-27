# frozen_string_literal: true
module Hyrax
  module Admin
    module Analytics
      class CollectionReportsController < ApplicationController
        layout 'hyrax/dashboard'

        def index
        # TODO Dynamic
          today = Time.current
          this_week = (DateTime.now.beginning_of_week..DateTime.now)
          #! config.beginning_of_week = :monday <--- add to config
          this_month = (today.beginning_of_month..DateTime.now)
          this_year = (today.beginning_of_year..DateTime.now)
          #! all_time = sum of all <--- need to add
        end

        def show
        end

      end
    end
  end
end
