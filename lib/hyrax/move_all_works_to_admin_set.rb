# If you want to move all your works to an admin set run this.
class MoveAllWorksToAdminSet
  include Blacklight::SearchHelper

  def self.run(admin_set)
    new(admin_set).run
  end

  def initialize(admin_set)
    @admin_set = admin_set
  end

  def run
    work_ids.each do |id|
      work = Hyrax::Queries.find_by(id: Valkyrie::ID.new(id))
      change_set = Hyrax::WorkChangeSet.new(work)
      params = { admin_set_id: @admin_set.id }
      raise "Unable to update work. #{change_set.errors.messages}" unless change_set.validate(params)
      change_set.sync
      change_set_persister.save(change_set: change_set)
    end
  end

  private

    delegate :blacklight_config, to: CatalogController

    def change_set_persister
      Hyrax::WorkChangeSetPersister.new(
        metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
        storage_adapter: Valkyrie.config.storage_adapter
      )
    end

    class SearchContext
      def initialize(user = nil)
        @user = user
      end
      attr_reader :user
    end

    def work_ids
      query = Hyrax::WorksSearchBuilder.new([:filter_models], self).query
      repository.search(query).response["docs"].map { |doc| doc["id"] }
    end
end
