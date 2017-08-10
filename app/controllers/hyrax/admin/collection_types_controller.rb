module Hyrax
  class Admin::CollectionTypesController < ApplicationController
    before_action do
      authorize! :manage, :collection_types
    end

    def index; end

    def new; end

    def create; end

    def edit; end

    def update; end

    def destroy; end
  end
end
