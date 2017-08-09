module Hyrax
  class Admin::CollectionTypesController < ApplicationController
    before_action do
      authorize! :manage, :collection_types
    end

    def index; end

    def new; end

    def edit; end
  end
end
