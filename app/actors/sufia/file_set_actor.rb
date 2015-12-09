module Sufia
  class FileSetActor < CurationConcerns::FileSetActor
    # Overrides the method in CurationConcerns::FileSetActor so that if a nil work
    # is passed, a default work is create instead.
    def create_metadata(work, file_set_params = {})
      work ||= default_work
      super
    end

    private

      def default_work
        GenericWork.create(title: ['Default title']) do |w|
          w.apply_depositor_metadata(user)
        end
      end
  end
end
