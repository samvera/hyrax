module Hyrax
  class ChangeContentDepositorService
    # @param [ActiveFedora::Base] work
    # @param [User] user
    # @param [TrueClass, FalseClass] reset
    def self.call(work, user, reset)
      new(work, user, reset).call
    end

    # @param [ActiveFedora::Base] work
    # @param [User] user
    # @param [TrueClass, FalseClass] reset
    def initialize(work, user, reset)
      @work = work
      @user = user
      @reset = reset
    end

    def call
      work.proxy_depositor = work.depositor
      work.permissions = [] if reset
      work.apply_depositor_metadata(user)
      file_sets.each do |fs|
        update_file_set(fs, user)
      end
      persister.save(resource: work)
      work
    end

    private

      attr_reader :work, :user, :reset

      def update_file_set(file_set, user)
        file_set.apply_depositor_metadata(user)
        persister.save(resource: file_set)
      end

      def file_sets
        Hyrax::Queries.find_members(resource: work, model: FileSet)
      end

      def persister
        Valkyrie::MetadataAdapter.find(:indexing_persister).persister
      end
  end
end
