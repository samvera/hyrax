# frozen_string_literal: true
module Hyrax
  ##
  # @api public
  #
  # Given a model class and an +id+, provides +ActiveModel+ style methods. This
  # is a tool for providing route resolution and other +ActiveModel+ behavior
  # for +ActiveFedora+ without loading the object from the fedora backend.
  #
  # @note this was originally implemented for +SolrDocument+ as
  #   +Hyrax::SolrDocumentBehavior::ModelWrapper+, but is useful in the more
  #   general case that we know the model class and id, but don't have a full
  #   model object.
  #
  class ActiveFedoraDummyModel
    ##
    # @api public
    #
    # @param [Class] model
    # @param [String, nil] id
    def initialize(model, id)
      @model = model
      @id = id
    end

    ##
    # @api public
    def persisted?
      true
    end

    ##
    # @api public
    def to_param
      @id
    end

    ##
    # @api public
    def to_key
      [@id]
    end

    ##
    # @api public
    def model_name
      @model.model_name
    end

    ##
    # @api public
    # @return [String]
    def human_readable_type
      @model.human_readable_type
    end

    ##
    # @api public
    #
    # @note uses the @model's `._to_partial_path` if implemented, otherwise
    #   constructs a default
    def to_partial_path
      return @model._to_partial_path if
        @model.respond_to?(:_to_partial_path)

      "hyrax/#{model_name.collection}/#{model_name.element}"
    end

    ##
    # @api public
    def to_global_id
      # this covers the use case of creating a non Valkyrie::Resource, while using Valkyrie
      if model_name.name.constantize <= Valkyrie::Resource
        URI::GID.build app: GlobalID.app, model_name: Hyrax::ValkyrieGlobalIdProxy.to_s, model_id: @id
      else
        URI::GID.build app: GlobalID.app, model_name: model_name.name, model_id: @id
      end
    end
  end
end
