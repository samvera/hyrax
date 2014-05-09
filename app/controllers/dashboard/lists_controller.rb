module Dashboard
  class ListsController < DashboardController
    # specify the controller_name here to specify where we should look for
    # the batch_edit menu options (_batch_edits_actions.html.erb)
    def controller_name
      :dashboard
    end

    def search_action_url(opts={})
      sufia.url_for(opts)
    end
  end
end
