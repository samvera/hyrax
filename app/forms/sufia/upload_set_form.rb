module Sufia
  class UploadSetForm
    include HydraEditor::Form

    self.terms = CurationConcerns::GenericWorkForm.terms

    delegate :creator, :human_readable_type, :open_access?, :authenticated_only_access?,
             :open_access_with_embargo_release_date?, :private_access?,
             :embargo_release_date, :lease_expiration_date, :member_ids, to: :exemplar_work

    def initialize(upload_set, current_ability)
      @current_ability = current_ability
      super(upload_set)
      # TODO: instead of using GenericWorkForm, this should be an UploadSetForm
      # work = ::GenericWork.new(creator: [creator_display], title: titles)
    end

    def exemplar_work
      @exemplar_work ||= GenericWork.new(creator: [creator_display])
    end

    # @return [Array] a list of the first titles for each of the works.
    def works
      @works ||= model.works.sort { |w1, w2| w1.title.first.downcase <=> w2.title.first.downcase }
    end

    def self.model_attributes(attrs)
      CurationConcerns::GenericWorkForm.model_attributes(attrs)
    end

    def self.multiple?(attrs)
      CurationConcerns::GenericWorkForm.multiple?(attrs)
    end

    private

      # Override this method if you want the creator to display something other than
      # the user_key, e.g. "current_user.user_key"
      def creator_display
        @current_ability.current_user.name
      end
  end
end
