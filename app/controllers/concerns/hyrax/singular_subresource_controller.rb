# frozen_string_literal: true
module Hyrax
  module SingularSubresourceController
    extend ActiveSupport::Concern
    include DenyAccessOverrideBehavior

    included do
      before_action :find_work, only: :work
      load_and_authorize_resource :work, only: :work
      load_and_authorize_resource :file, class: 'FileSet', only: :file, id_param: :id
    end

    def find_work
      @work = Hyrax::WorkRelation.new.find(params[:id])
    end
  end
end
