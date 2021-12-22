  // function to hide or show the batch update buttons based on how may items are checked
  function toggleButtons(forceOn, otherPage ){
    forceOn = typeof forceOn !== 'undefined' ? forceOn : false
    otherPage = typeof otherPage !== 'undefined' ? otherPage : !window.batch_part_on_other_page;
    var n = $(".batch_document_selector:checked").length;
    if ((n>0) || (forceOn)) {
        $('.batch-toggle').show();
        $('.batch-select-all').prop('hidden', false);
        $('#batch-edit').prop('hidden', false);
    } else if (otherPage){
        $('.batch-toggle').hide();
        $('.batch-select-all').prop('hidden', true);
        $('#batch-edit').prop('hidden', true);
    }
    $("body").css("cursor", "auto");
  }


  // change the state of a cog menu item and add or remove the check beside it
  // using on or off instead of true or false
  function toggleState (obj, state) {
    toggleStateBool(obj, state == 'on');
  }

  // change the state of a cog menu item and add or remove the check beside it
  function toggleStateBool (obj, state) {
    if (state){
      obj.attr("data-state", 'on');
      obj.find('a i').addClass('glyphicon glyphicon-ok');
    }else {
      obj.attr("data-state", 'off');
      obj.find('a i').removeClass('glyphicon glyphicon-ok');
    }

  }


  // check all the check boxes on the page
  function check_all_page(e) {
    // get the check box state
    var checked = $("#check_all")[0]['checked'];

    // check each individual box
    $("input[type='checkbox'].batch_document_selector").each(function(index, value) {
       value['checked'] = checked;
    });
    toggleButtons();

    // set menu check marks
    toggleStateBool($("[data-behavior='batch-edit-select-page']"),checked);
    toggleStateBool($("[data-behavior='batch-edit-select-none']"),!checked);

  }

  // turn page selection on or off
  // state == true for on
  function select_page ( state) {
    // check everything on the current page on or off based on state
    $("#check_all").prop('checked', state);
    check_all_page();
  }

Blacklight.onLoad(function() {
  // check the select all page cog menu item and select the entire page
  $("[data-behavior='batch-edit-select-page']").bind('click', function(e) {
    e.preventDefault();
    select_page(true);
  });

  // check the select none cog menu item and de-select the entire page
  $("[data-behavior='batch-edit-select-none']").bind('click', function(e) {
    e.preventDefault();
    select_page(false);
  });

  // check all check boxes
  $("#check_all").bind('click', check_all_page);
  
  // select/deselect all check boxes 
  $("#checkAllBox").change(function () {
    $("input:checkbox").prop('checked', $(this).prop("checked"));
  });

  // Check files within
  $('[checks="active"]').on('click', function(evt) {
     $("[value=" + this.value + "]").prop('checked', $(this).prop("checked"));
  });

  // toggle button on or off based on boxes being clicked
  $(".batch_document_selector").bind('click', function(e) {
     toggleButtons();
  });

  // toggle the state of the select boxes in the cog menu if all buttons are
  $(".batch_document_selector").bind('click', function(e) {

      // count the check boxes currently checked
      var selectedCount = $(".batch_document_selector:checked").length;

      // toggle the cog menu check boxes
      toggleStateBool($("[data-behavior='batch-edit-select-page']"),selectedCount == window.document_list_count);
      toggleStateBool($("[data-behavior='batch-edit-select-none']"),selectedCount == 0);

      // toggle the check all check box
      $("#check_all").attr('checked', (selectedCount == window.document_list_count));

    });

    if ($("#check_all").length > 0) select_page(false);

});
