Blacklight.onLoad(function () {

  // change the action based which collection is selected
  $('input.updates-collection').on('click', function() {
 
      var form = $(this).closest("form"); 
      var collection_id = $(".collection-selector:checked")[0].value;      
      form[0].action = form[0].action.replace("collection_replace_id",collection_id);
      form.append('<input type="hidden" value="add" name="collection[members]"></input>');
      
  });

});
