Blacklight.onLoad(function () {
  $('input.submits-batches').on('click', function() {  
      var form = $(this).closest("form"); 
      $.map( $(".batch_document_selector:checked"), function(document, i) {
         var id = document.id.substring("batch_document_".length);
         if (form.children("input[value='"+id+"']").length == 0)
           form.append('<input type="hidden" multiple="multiple" name="batch_document_ids[]" value="'+id+'" />');
      });
  });
});
