# frozen_string_literal: true
module Hyrax
  class Admin::StatsController < ApplicationController
    include Hyrax::Admin::StatsBehavior
  end
end
