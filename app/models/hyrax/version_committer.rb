# frozen_string_literal: true
module Hyrax
  class VersionCommitter < ActiveRecord::Base
    self.table_name = 'version_committers'
  end
end
