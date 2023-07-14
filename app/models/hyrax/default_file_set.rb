# frozen_string_literal: true
module Hyrax
  class DefaultFileSet < ActiveFedora::Base
    include ::Hyrax::FileSetBehavior
  end
end
