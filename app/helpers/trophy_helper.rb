# -*- coding: utf-8 -*-
module TrophyHelper
 def display_trophy_link(user, noid)
   trophyclass = "trophy-off"
   trophytitle= "Highlight File on Profile"
   if user.trophies.map(&:generic_file_id).include? noid
     trophyclass = "trophy-on"
   end

   return link_to raw("<i class='#{trophyclass} icon-trophy'></i> #{trophytitle}"),"", :class=> 'trophy-class', :title => trophytitle, :id => noid,  :remote=>true # link to trophy
 end
end
