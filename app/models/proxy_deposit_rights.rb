# frozen_string_literal: true
class ProxyDepositRights < ActiveRecord::Base
  belongs_to :grantor, class_name: "User"
  belongs_to :grantee, class_name: "User"
end
