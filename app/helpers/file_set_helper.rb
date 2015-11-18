# -*- coding: utf-8 -*-
module FileSetHelper
  def display_title(fs)
    fs.to_s
  end

  def present_terms(presenter, terms = :all, &block)
    terms = presenter.terms if terms == :all
    Sufia::PresenterRenderer.new(presenter, self).fields(terms, &block)
  end

  def render_download_icon(title = nil)
    if title.nil?
      link_to download_image_tag, download_path(@file_set), target: "_blank", title: "Download the document", id: "file_download", data: { label: @file_set.id }
    else
      label = download_image_tag(title) + title
      link_to label, download_path(@file_set), target: "_blank", title: title, id: "file_download", data: { label: @file_set.id }
    end
  end

  def render_download_link(label = 'Download')
    link_to label, download_path(@file_set), id: "file_download", target: "_new", data: { label: @file_set.id }
  end

  def render_collection_list(fs)
    return if fs.collections.empty?
    ("Is part of: " + fs.collections.map { |c| link_to(c.title, collections.collection_path(c)) }.join(", ")).html_safe
  end

  def display_multiple(value)
    auto_link(value.join(" | "))
  end

  private

    def download_image_tag(title = nil)
      if title.nil?
        image_tag "default.png", alt: "No preview available", class: "img-responsive"
      else
        image_tag download_path(@file_set, file: 'thumbnail'), class: "img-responsive", alt: "#{title} of #{@file_set.title.first}"
      end
    end

    def render_visibility_badge
      if can? :edit, @file_set
        render_visibility_link @file_set
      else
        render_visibility_label @file_set
      end
    end
end
