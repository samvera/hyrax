# -*- coding: utf-8 -*-
module Sufia
  class StatsAdmin
    def self.matches?(request)
      current_user = request.env['warden'].user
      return false if current_user.blank?
      current_user.groups.include? 'admin'
    end
  end
end
