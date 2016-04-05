module CurationConcerns
  class QuickClassificationQuery
    attr_reader :user

    # @param [User] user the current user
    # @param [Hash] options
    # @option options [#call] :concern_name_normalizer (ClassifyConcern.to_class) a proc that translates names to classes
    # @option options [Array<String>] :models the options to display, defaults to everything.
    def initialize(user, options = {})
      @user = user
      @concern_name_normalizer = options.fetch(:concern_name_normalizer, ClassifyConcern.method(:to_class))
      @models = options.fetch(:models, CurationConcerns.config.registered_curation_concern_types)
    end

    def each(&block)
      authorized_models.each(&block)
    end

    # @return true if the requested concerns is same as all avaliable concerns
    def all?
      models == CurationConcerns.config.registered_curation_concern_types
    end

    # @return [Array] a list of all the requested concerns that the user can create
    def authorized_models
      normalized_model_names.select { |klass| user.can?(:create, klass) }
    end

    private

      attr_reader :concern_name_normalizer, :models

      # Transform the list of requested model names into a list of class names
      def normalized_model_names
        models.map { |name| concern_name_normalizer.call(name) }
      end
  end
end
