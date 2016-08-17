module Sufia::SingularSubresourceController
  extend ActiveSupport::Concern
  include DenyAccessOverrideBehavior

  included do
    before_action :find_work, only: :work
    load_and_authorize_resource :work, only: :work
    load_and_authorize_resource :file, class: 'FileSet', only: :file, id_param: :id
  end

  def find_work
    @work = CurationConcerns::WorkRelation.new.find(params[:id])
  end
end
