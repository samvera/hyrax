# Added to allow for the My controller to show only things I have edit access to
class Sufia::MySharesSearchBuilder < Sufia::SearchBuilder
  include Sufia::MySearchBuilderBehavior

  self.default_processor_chain = default_processor_chain - [:filter_models] + [:show_only_shared_files, :show_only_file_sets]
end
