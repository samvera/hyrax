# -*- coding: utf-8 -*-
module GenericFileHelper
  def display_title(gf)
    gf.to_s
  end

  def required?(key)
    [:title, :creator, :tag, :rights].include?(key)
  end

  def render_show_field_partial(key, locals)
    render_show_field_partial_with_action('generic_files', key, locals)
  end

  def render_edit_field_partial(key, locals)
    render_edit_field_partial_with_action('generic_files', key, locals)
  end

  def render_batch_edit_field_partial(key, locals)
    render_edit_field_partial_with_action('batch_edit', key, locals)
  end

  def render_download_icon title = nil
    if title.nil?
      link_to download_image_tag, sufia.download_path(@generic_file.id), { target: "_blank", title: "Download the document", id: "file_download", data: { label: @generic_file.id } }
    else
      link_to (download_image_tag(title) + title), sufia.download_path(@generic_file), { target: "_blank", title: title, id: "file_download", data: { label: @generic_file.id } }
    end
  end

  def render_download_link text = nil
    link_to (text || "Download"), sufia.download_path(@generic_file.noid), { id: "file_download", target: "_new", data: { label: @generic_file.id } }
  end

  def render_collection_list gf
    unless gf.collections.empty?
      ("Is part of: " + gf.collections.map { |c| link_to(c.title, collections.collection_path(c.id)) }.join(", ")).html_safe
    end
  end

  private

  def render_edit_field_partial_with_action(action, key, locals)
    ["#{action}/edit_fields/#{key}", "#{action}/edit_fields/default"].each do |str|
      # XXX rather than handling this logic through exceptions, maybe there's a Rails internals method
      # for determining if a partial template exists..
      begin
        return render partial: str, locals: locals.merge({ key: key })
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
        return render partial: str, locals: locals.merge({ key: key })
      rescue ActionView::MissingTemplate
        nil
      end
    end
  end

  def more_or_less_button(key, html_class, symbol)
    # TODO, there could be more than one element with this id on the page, but the fuctionality doesn't work without it.
    content_tag('button', class: "#{html_class} btn", id: "additional_#{key}_submit", name: "additional_#{key}") do
      (symbol + content_tag('span', class: 'sr-only') do
        "add another #{key.to_s}"
      end).html_safe
    end
  end

  def download_image_tag title = nil
    if title.nil?
      image_tag "default.png", { alt: "No preview available", class: "img-responsive" }
    else
      image_tag sufia.download_path(@generic_file, datastream_id: 'thumbnail'), { class: "img-responsive", alt: "#{title} of #{@generic_file.title.first}" }
    end
  end

  def render_visibility_badge
    if can? :edit, @generic_file
      render_visibility_link @generic_file
    else
      render_visibility_label @generic_file
    end
  end

end
