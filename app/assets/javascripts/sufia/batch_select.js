Blacklight.onLoad(function () {

  // add the batch ids to any submit of a batch update
  var batch_ids = null;
  $('input.updates-batches').on('click', function() {  
    var form = $(this).closest("form"); 
    var hash, id;

    // pull the ids from the url
    if (!batch_ids) {
      batch_ids = [];
      // pull the ids from the url
      var q = document.URL.split('?')[1];
      if(q != undefined){
          q = q.split('&');
          for(var i = 0; i < q.length; i++){
              hash = q[i].split('=');
              if (hash[0] == "batch_document_ids%5B%5D")
                 batch_ids.push(unescape(hash[1]));
          }
       }
    }

    // push the ids in the form
    for(var j = 0; j < batch_ids.length; j++){
      if (form.children("input[value='"+batch_ids[j]+"']").length == 0)
        form.append('<input type="hidden" multiple="multiple" name="batch_document_ids[]" value="'+batch_ids[j]+'" />');
    }
      
  });
  $('input.submits-batches').on('click', function() {  
      var form = $(this).closest("form"); 
      $.map( $(".batch_document_selector:checked"), function(document, i) {
         var id = document.id.substring("batch_document_".length);
         if (form.children("input[value='"+id+"']").length == 0)
           form.append('<input type="hidden" multiple="multiple" name="batch_document_ids[]" value="'+id+'" />');
      });
  
      
  });

});
