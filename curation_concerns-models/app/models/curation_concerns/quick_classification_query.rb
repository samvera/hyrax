module CurationConcerns
  class QuickClassificationQuery

    def self.each_for_context(*args, &block)
      new(*args).all.each(&block)
    end

    attr_reader :user

    def initialize(user, options = {})
      @user = user
      @concern_name_normalizer = options.fetch(:concern_name_normalizer, ClassifyConcern.method(:to_class))
      @registered_curation_concern_names = options.fetch(:registered_curation_concern_names, CurationConcerns.configuration.registered_curation_concern_types)
    end

    def all
      ActiveFedora::Base.logger.debug "User is #{user}"
      ActiveFedora::Base.logger.debug "try is #{normalized_curation_concern_names.first}"
      ActiveFedora::Base.logger.debug "can is  #{user.can?(:create, normalized_curation_concern_names.first)}"
      normalized_curation_concern_names.select {|klass| user.can?(:create, klass)}
    end

    private

    attr_reader :concern_name_normalizer, :registered_curation_concern_names

    def normalized_curation_concern_names
      registered_curation_concern_names.collect{|name| concern_name_normalizer.call(name) }
    end
  end
end
