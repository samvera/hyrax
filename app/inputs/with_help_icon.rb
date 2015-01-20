module WithHelpIcon
  def label(wrapper_options = nil)
    "#{super} #{link_to_help}"
  end

  protected
    def link_to_help
      template.link_to '#', id: "#{input_class}_help", rel: 'popover'.freeze,
              :'data-content' => metadata_help, :'data-original-title' => raw_label_text,
              :'aria-label' => aria_label do
        help_icon
      end
    end

    def help_icon
      template.content_tag 'i', nil, :"aria-hidden" => true, class: "help-icon"
    end

    def metadata_help
      translate_from_namespace(:metadata_help) || attribute_name.to_s.humanize
    end


    def aria_label
      translate_from_namespace(:aria_label) || default_aria_label
    end

    def default_aria_label
      I18n.t("#{i18n_scope}.aria_label.#{lookup_model_names.join('.')}.default",
             title: attribute_name.to_s.humanize)
    end
end
