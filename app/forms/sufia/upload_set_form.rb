module Sufia
  class UploadSetForm < CurationConcerns::UploadSetForm
    private

      # overridden to use display name
      def creator_display
        @current_ability.current_user.name
      end
  end
end
