# frozen_string_literal: true
module Sipity
  # Represents a "comment" placed by the given :agent in regards to the give :entity
  class Comment < ActiveRecord::Base
    self.table_name = 'sipity_comments'

    belongs_to :agent, class_name: 'Sipity::Agent'
    belongs_to :entity, class_name: 'Sipity::Entity'

    def name_of_commentor
      agent.proxy_for.to_s
    end
  end

  ##
  # A comment without a database record; always returns an empty string
  class NullComment
    attr_reader :agent, :entity

    def initialize(agent:, entity:)
      @agent = agent
      @entity = entity
    end

    ##
    # @return [String]
    def comment
      ''
    end
  end
end
