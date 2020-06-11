# frozen_string_literal: true
module Hyrax
  class Admin::UsersController < ApplicationController
    include Hyrax::Admin::UsersControllerBehavior
  end
end
