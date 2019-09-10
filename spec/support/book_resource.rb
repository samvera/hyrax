# frozen_string_literal: true

class BookResource < Hyrax::Resource
  attribute :title,    Valkyrie::Types::String
  attribute :author,   Valkyrie::Types::String
  attribute :created,  Valkyrie::Types::Date
  attribute :isbn,     Valkyrie::Types::String
  attribute :pubisher, Valkyrie::Types::String
end
