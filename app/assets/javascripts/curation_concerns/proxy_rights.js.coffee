(($, window, document) ->
  $this = undefined
 
  # default settings
  _settings =
    default: 'cool!'
    
 
  # This is your public API (no leading underscore, see?)
  # All public methods must return $this so your plugin is chainable.
  methods =
    init: (options) ->
      $this = $(@)
      # The settings object is available under its name: _settings. Let's
      # expand it with any custom options the user provided.
      $.extend _settings, (options or {})
      # Do anything that actually inits your plugin, if needed, right now!
      # An important thing to keep in mind, is that jQuery plugins should be
      # built so that one can apply them to more than one element, like so:
      #
      #  $('.matching-elements, #another-one').foobar()
      #
      $this.each (index, el) ->
        $('#user').each (index, el) ->
          _internals.autocompleteUsers(el)

        $(el).on 'click', '.remove-proxy-button', _internals.removeContributor

      return $this
 
    # This method is often overlooked.
    destroy: ->
      # Do anything to clean it up (nullify references, unbind events…).
      return $this
 
  _internals =
    addContributor: (name, id) ->
      source   = $("#tmpl-proxy-row").html()
      template = Handlebars.compile(source)
      row = template({name: name, id: id})
      $('#authorizedProxies tbody', $this).append(row)

      # if (settings.afterAdd) {
      #   settings.afterAdd(this, cloneElem)
      # }

      $.ajax({
        type: "POST",
        url: 'depositors',
        dataType: 'json',
        data: {grantee_id: id}
      })

      false

    removeContributor: ->
      # remove the row
      $.ajax({
        url: $(this).closest('a').prop('href'),
        type: "post",
        dataType: "json",
        data: {"_method":"delete"}
      })
      $(this).closest('tr').remove()
      false

    autocompleteUsers: (el) ->
      # Remove the choice from the search widget and put it in the table.
      $targetElement = $(el)
      $targetElement.autocomplete
        source: (request, response) ->
          $targetElement.data('url')
          $.getJSON $targetElement.data('url'), { q: request.term, user: true}, ( data, status, xhr ) ->
            matches = []
            $.each data.response.docs, (idx, val) ->
              matches.push {label: val['name_tesim'][0], value: val['id']}
            response( matches )
        minLength: 2
        focus: ( event, ui ) ->
          $targetElement.val(ui.item.label)
          event.preventDefault()
        select: ( event, ui ) ->
          _internals.addContributor(ui.item.label, ui.item.value)
          $targetElement.val('')
          event.preventDefault()

 
  $.fn.proxyRights = (method) ->
    if methods[method]
      methods[method].apply this, Array::slice.call(arguments, 1)
    else if typeof method is "object" or not method
      methods.init.apply this, arguments
    else
      $.error "Method " + method + " does not exist on jquery.proxyRights"
) jQuery, window, document
