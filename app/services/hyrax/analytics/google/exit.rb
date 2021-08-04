module Exit
  extend Legato::Model

  metrics :exits, :pageviews
  dimensions :page_path, :operating_system, :browser

end