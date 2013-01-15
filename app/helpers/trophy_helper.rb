# -*- coding: utf-8 -*-
# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module TrophyHelper
 def display_trophy_link(user, noid)
   trophyclass = "trophy-off"
   trophytitle= "Highlight work "
   if user.trophies.map(&:generic_file_id).include? noid
     trophyclass = "trophy-on"
     trophytitle= "Unhighlight work"
   end

   return link_to raw("<i class='#{trophyclass} icon-trophy icon-large'></i>"),"", :class=> 'trophy-class', :title => trophytitle, :id => noid,  :remote=>true # link to trophy
 end
end
