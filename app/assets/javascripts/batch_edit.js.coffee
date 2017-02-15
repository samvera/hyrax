$ = jQuery

$.fn.batchEdit = (args) ->
  $elem = this
  $("[data-behavior='batch-tools']", $elem).removeClass('hidden')

  window.batch_edits_options = {}  if typeof window.batch_edits_options is "undefined"
  default_options =
          checked_label: "Selected",
          unchecked_label: "Select",
          css_class: "batch_toggle"

  options = $.extend({}, default_options, window.batch_edits_options)

  # complete the override by overriding update_state_for  
  update_state_for = (check, state, label, form) ->
    check.prop "checked", state
    label.toggleClass "checked", state

    if state
      form.find("input[name=_method]").val "delete"
      $('span', label).text(options.progress_label)
    else
      form.find("input[name=_method]").val "put"
      $('span', label).text(options.progress_label)
      
  for obj in $("[data-behavior='batch-add-form']", $elem)
    form = $(obj)
    form.children().hide()
    # We're going to use the existing form to actually send our add/removes
    # This works conveneintly because the exact same action href is used
    # for both bookmarks/$doc_id.  But let's take out the irrelevant parts
    # of the form to avoid any future confusion. 
    form.find("input[type=submit]").remove()
    form.addClass('form-inline')
          
    # View needs to set data-doc-id so we know a unique value
    # for making DOM id
    unique_id = form.attr("data-doc-id") || Math.random()
    # if form is currently using method delete to change state, 
    # then checkbox is currently checked
    checked = (form.find("input[name=_method][value=delete]").length != 0)
        
    checkbox = $('<input type="checkbox">')
      .addClass( options.css_class )
      .attr("id", options.css_class + "_" + unique_id)
    label = $('<label>')
      .addClass( options.css_class )
      .addClass('checkbox')
      .attr("for", options.css_class + '_' + unique_id)
      .attr("title", form.attr("title") || "")
    span = $('<span>')

    label.append(checkbox)
    label.append(" ")
    label.append(span)
    update_state_for(checkbox, checked, label, form)
    form.append(label)

    #allow the user to bind some actions to the check box after it has been updated
    args.afterCheckboxUpdate(checkbox)  if args.afterCheckboxUpdate

    # TODO make this into a new method
    checkbox.bind 'click', ->
      cb = $(this)
      chkd = not cb.is(":checked")
      form = $(cb.closest('form')[0])
      label = $('label[for="'+$(this).attr('id')+'"]')
      label.attr "disabled", "disabled"
      $('span', label).text(options.progress_label)
      cb.attr "disabled", "disabled"
      ajaxManager.addReq
        queue: "add_doc"
        url: form.attr("action")
        dataType: "json"
        type: form.attr("method").toUpperCase()
        data: form.serialize()
        error: ->
          alert "Error  Too Many results Selected"
          update_state_for cb, chkd, label, form
          label.removeAttr "disabled"
          checkbox.removeAttr "disabled"
    
        success: (data, status, xhr) ->
          unless xhr.status is 0
            chkd = not chkd
          else
            alert "Error Too Many results Selected"
          update_state_for cb, chkd, label, form
          label.removeAttr "disabled"
          cb.removeAttr "disabled"

      false
    

  setState = (obj) ->
    activate = ->
      obj.find('a i').addClass('icon-ok')
      $("[data-behavior='batch-edit']").removeClass('hidden')
      $("[data-behavior='batch-add-button']").removeClass('hidden')
      $("[data-behavior='batch-select-all']").removeClass('hidden')

    deactivate = ->
      obj.find('a i').removeClass('icon-ok')
      $("[data-behavior='batch-edit']").addClass('hidden')
      $("[data-behavior='batch-add-button']").addClass('hidden')
      $("[data-behavior='batch-select-all']").addClass('hidden')

    if obj.attr("data-state") == 'off'
      deactivate(obj)
    else
      activate(obj)

  toggleState = (obj) ->
    if obj.attr('data-state') == 'off'
      obj.attr("data-state", 'on')
    else
      obj.attr("data-state", 'off')
    setState(obj)

  #set initial state
  setState($("[data-behavior='batch-edit-activate']", $elem))

  $("[data-behavior='batch-edit-activate']", $elem).click (e) ->
    e.preventDefault()
    toggleState($(this))
    $.ajax({
      type: 'POST',
      url: '/batch_edits/state',
      data: {_method:'PUT', state: $(this).attr('data-state')},
    })
    # TODO check-all

  # ajax manager to queue ajax calls so all adds or removes are done in sequence
  queue = ->
    requests = []
    addReq: (opt) ->
      requests.push opt
  
    removeReq: (opt) ->
      requests.splice $.inArray(opt, requests), 1  if $.inArray(opt, requests) > -1
  
    run: ->
      self = this
      orgSuc = undefined
      if requests.length
        oriSuc = requests[0].complete
        requests[0].complete = ->
          oriSuc()  if typeof oriSuc is "function"
          requests.shift()
          self.run.apply self, []
  
        $.ajax requests[0]
      else
        self.tid = setTimeout(->
          self.run.apply self, []
        , 1000)
  
    stop: ->
      requests = []
      clearTimeout @tid
  
  ajaxManager = (queue())
  
  ajaxManager.run()

