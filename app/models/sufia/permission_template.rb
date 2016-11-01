module Sufia
  class PermissionTemplate < ActiveRecord::Base
    has_many :access_grants, class_name: 'Sufia::PermissionTemplateAccess'
    accepts_nested_attributes_for :access_grants, reject_if: :all_blank
  end
end
