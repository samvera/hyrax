# -*- coding: utf-8 -*-
module GenericFileHelper
  def display_title(gf)
    gf.to_s
  end

  def required?(key)
    [:title, :creator, :tag, :rights].include?(key)
  end

  def render_edit_field_partial(key, locals)
    render_edit_field_partial_with_action('generic_files', key, locals)
  end

  def render_batch_edit_field_partial(key, locals)
    render_edit_field_partial_with_action('batch_edit', key, locals)
  end
  
  def render_show_field_partial(key, locals)
    render_show_field_partial_with_action('generic_files', key, locals)
  end

 private 

  def render_edit_field_partial_with_action(action, key, locals)
    ["#{action}/edit_fields/#{key}", "#{action}/edit_fields/default"].each do |str|
      # XXX rather than handling this logic through exceptions, maybe there's a Rails internals method
      # for determining if a partial template exists..
      begin
        return render :partial => str, :locals=>locals.merge({key: key})
      rescue ActionView::MissingTemplate
        nil
      end
    end
  end
  
  def render_show_field_partial_with_action(action, key, locals)
    ["#{action}/show_fields/#{key}", "#{action}/show_fields/default"].each do |str|
      # XXX rather than handling this logic through exceptions, maybe there's a Rails internals method
      # for determining if a partial template exists..
      begin
        return render :partial => str, :locals=>locals.merge({key: key})
      rescue ActionView::MissingTemplate
        nil
      end
    end
  end
end
