jQuery ->
  $('.autocomplete').each( (index, el) ->
    $targetElement = $(el)
    $targetElement.tokenInput $targetElement.data("url"), {
      theme: 'facebook'
      prePopulate: $('.autocomplete').data('load')
      jsonContainer: "docs"
      propertyToSearch: "title"
      preventDuplicates: true
      tokenValue: "pid"
      onResult: (results) ->
        pidsToFilter = $targetElement.data('exclude')
        $.each(results.docs, (index, value) ->
          # Filter out anything listed in data-exclude.  ie. the current object.
          if (pidsToFilter.indexOf(value.pid) > -1)
            results.docs.splice(index, 1)
        )
        return results
    }
  )
