# -*- coding: utf-8 -*-
module Hyrax
  module TrophyHelper
    def display_trophy_link(user, id, args = {}, &_block)
      return unless user
      trophy = user.trophies.where(work_id: id).exists?
      trophyclass = trophy ? "trophy-on" : "trophy-off"

      args[:add_text] ||= "Highlight Work on Profile"
      args[:remove_text] ||= "Unhighlight Work"
      text = trophy ? args[:remove_text] : args[:add_text]
      args[:class] = [args[:class], "trophy-class #{trophyclass}"].compact.join(' ')
      args[:data] ||= {}
      args[:data]['add-text'] = args[:add_text]
      args[:data]['remove-text'] = args[:remove_text]

      args[:data][:url] = hyrax.trophy_work_path(id)
      link_to '#', class: args[:class], data: args[:data] do
        yield(text)
      end
    end
  end
end
