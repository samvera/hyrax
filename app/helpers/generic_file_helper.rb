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

module GenericFileHelper
  def display_title(gf)
    title =  gf.title.join(' | ')
    title = gf.label if title.blank?
    title = 'No Title' if title.blank?
    title
  end

  def add_field (key)
    more_or_less_button(key, 'adder', '+')
  end

  def subtract_field (key)
   more_or_less_button(key, 'remover', '-')
  end

  def help_icon(key)
    link_to '#', id: "generic_file_#{key.to_s}_help", rel: 'popover', 
      'data-content' => metadata_help(key),
      'data-original-title' => get_label(key) do
        content_tag 'i', '', class: "icon-question-sign icon-large"
    end
  end

  def metadata_help(key)
    I18n.t("sufia.metadata_help.#{key}", default: key.to_s.humanize)
  end

  def get_label(key)
    I18n.t("sufia.field_label.#{key}", default: key.to_s.humanize)
  end

  def required?(key)
    [:title, :creator, :tag, :rights].include?(key)
  end

  def render_edit_field_partial(key, locals)
    ["generic_files/edit_fields/#{key}", "generic_files/edit_fields/default"].each do |str|
      # XXX rather than handling this logic through exceptions, maybe there's a Rails internals method
      # for determining if a partial template exists..
      begin
        return render :partial => str, :locals=>locals.merge({key: key})
      rescue ActionView::MissingTemplate
        nil
      end
    end
  end

 private 

 def more_or_less_button(key, html_class, symbol)
   # TODO, there could be more than one element with this id on the page, but the fuctionality doesn't work without it.
   content_tag('button', class: "#{html_class} btn", id: "additional_#{key}_submit", name: "additional_#{key}") do
     (symbol + 
     content_tag('span', class: 'accessible-hidden') do
       "add another #{key.to_s}"
     end).html_safe
   end
 end
end
