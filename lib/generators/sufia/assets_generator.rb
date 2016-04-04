# -*- encoding : utf-8 -*-
require 'rails/generators'

class Sufia::AssetsGenerator < Rails::Generators::Base
  desc """
    This generator installs the sufia CSS assets into your application
       """

  source_root File.expand_path('../templates', __FILE__)

  def inject_css
    copy_file "sufia.scss", "app/assets/stylesheets/sufia.scss"
  end

  def inject_js
    return if sufia_javascript_installed?
    insert_into_file 'app/assets/javascripts/application.js', after: '//= require_tree .' do
      <<-EOF.strip_heredoc

        //= require sufia
      EOF
    end
  end

  private

    def sufia_javascript_installed?
      IO.read("app/assets/javascripts/application.js").include?('sufia')
    end
end
