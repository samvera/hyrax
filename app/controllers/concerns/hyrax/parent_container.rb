module Hyrax
  module ParentContainer
    extend ActiveSupport::Concern

    included do
      helper_method :parent
    end

    # TODO: this is slow, refactor to return a Presenter (fetch from solr)
    def parent
      @parent ||= new_or_create? ? find_parent_by_id : lookup_parent_from_child
    end

    def find_parent_by_id
      Hyrax::Queries.find_by(id: parent_id)
    end

    def lookup_parent_from_child
      return find_parent_objects(curation_concern).first if curation_concern
      return ParentService.parent_for(@presenter.id) if @presenter
      raise "no child"
    end

    def parent_id
      @parent_id ||= new_or_create? ? params[:parent_id] : lookup_parent_from_child.id
    end

    private

      def new_or_create?
        %w[create new].include? action_name
      end

      def find_parent_objects(curation_concern)
        Hyrax::Queries.find_inverse_references_by(resource: curation_concern, property: :member_ids)
      end
  end
end
