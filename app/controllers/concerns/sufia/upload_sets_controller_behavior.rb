module Sufia
  module UploadSetsControllerBehavior
    extend ActiveSupport::Concern

    included do
      layout "sufia-one-column"

      before_action :has_access?
      self.edit_form_class = Sufia::UploadSetForm
    end

    protected

      def redirect_after_update
        if uploading_on_behalf_of? @upload_set
          redirect_to sufia.dashboard_shares_path
        else
          redirect_to sufia.dashboard_works_path
        end
      end

      def uploading_on_behalf_of?(upload_set)
        return false if upload_set.works.empty?

        work = upload_set.works.first
        return false if work.nil? || work.on_behalf_of.blank?
        current_user.user_key != work.on_behalf_of
      end
  end
end
