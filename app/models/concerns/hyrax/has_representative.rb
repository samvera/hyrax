# frozen_string_literal: true
module Hyrax::HasRepresentative
  extend ActiveSupport::Concern

  included do
    belongs_to :representative,
               predicate: ::RDF::Vocab::EBUCore.hasRelatedMediaFragment,
               class_name: 'ActiveFedora::Base'

    belongs_to :thumbnail,
               predicate: ::RDF::Vocab::EBUCore.hasRelatedImage,
               class_name: 'ActiveFedora::Base'
  end
end
