  // function to hide or show the batch update buttons based on how may items are checked
  function toggleButtons(forceOn, otherPage ){
    forceOn = typeof forceOn !== 'undefined' ? forceOn : false
    otherPage = typeof otherPage !== 'undefined' ? otherPage : !window.batch_part_on_other_page;
    var n = $(".batch_toggle:checked").length;
    if ((n>0) || (forceOn)) {
        $('.batch-select-all').show();
        $('.button_to').show();
    } else if ( otherPage){
        $('.batch-select-all').hide();
        $('.button_to').hide();
    }
    $("body").css("cursor", "auto");
  }

  function toggleState (obj, state) {
    if (state == 'on'){
      obj.attr("data-state", 'on');
      obj.find('a i').addClass('icon-ok');
    }else {
      obj.attr("data-state", 'off');
      obj.find('a i').removeClass('icon-ok');
    }

  }

  function check_all_page(e) {
     var checked = $("#check_all")[0]['checked'];

     // only check the current page
     var timeout = 0;
     var timeoutInc = 60;
     
     $("input[type='checkbox'].batch_toggle").each(function(index, value) {
        // check each individual box
        var ck = value['checked'];
        console.log("status for ");
        console.log(value);
        // not the same state click the box
        if (checked != ck) {
          console.log("click it");
          window.parent.setTimeout(function(){value.click();},timeout);
        }
        timeout+=timeoutInc; 
     });
     window.parent.setTimeout(toggleButtons,timeout+500);     
     $("#check_all").attr('checked', checked);
  }

  function clear_batch () {
    var url = '<%=clear_batch_edits_path %>';
    var clearState = $.ajax({
      headers: {           
           Accept : "application/javascript",          
       },      
      type: 'PUT',
      url: url,
      async: false,
    });

  }
  
  function set_all_checkboxes(checked){
    $("input[type='checkbox'].batch_toggle").each(function(){
      $(this).attr('checked', checked);   
      
      // make sure the form is set correctly
      form = $($(this).parent()[0]);      
      if (checked) {
        form.find("input[name=_method]").val("delete");

      } else {
        form.find("input[name=_method]").val("put");
      }
    });
    
  }
 

$(document).ready(function() { 

  $("[data-behavior='batch-edit-select-page']").bind('click', function(e) {
    $("body").css("cursor", "progress");
    e.preventDefault();
    $("#check_all").attr('checked', true);
    toggleState($(this),'on');    
    toggleState($("[data-behavior='batch-edit-select-all']"),'off');    
    toggleState($("[data-behavior='batch-edit-select-none']"),'off');    
    clear_batch();
    
    // uncheck everything on the current page
    set_all_checkboxes(false);
    
    // check everything on the current page
    check_all_page();
    
  });

  $("[data-behavior='batch-edit-select-all']").bind('click', function(e) {
    $("body").css("cursor", "progress");
    e.preventDefault();
    $("#check_all").attr('checked', true);
    toggleState($(this), 'on');    
    toggleState($("[data-behavior='batch-edit-select-page']"),'off');    
    toggleState($("[data-behavior='batch-edit-select-none']"),'off');    
    var url =  '<%=all_batch_edits_path %>';
    var clearState = $.ajax({
      headers: {           
           Accept : "application/javascript",          
       },      
      type: 'PUT',
      url: url,
      async: false,
    });
    
    // show that update on the local screen
    set_all_checkboxes(true)
    $("body").css("cursor", "auto");
    toggleButtons(true);
  });

  $("[data-behavior='batch-edit-select-none']").bind('click', function(e) {
    $("body").css("cursor", "progress");
    e.preventDefault();
    $("#check_all").attr('checked', false);
    toggleState($(this), 'on');    
    toggleState($("[data-behavior='batch-edit-select-page']"),'off');    
    toggleState($("[data-behavior='batch-edit-select-all']"),'off');  
    clear_batch();  

    // show that update on the local screen
    set_all_checkboxes(false)
    $("body").css("cursor", "auto");
    toggleButtons(false, true);
  });

  
  
  // check all buttons
  $("#check_all").bind('click', check_all_page);
  

  $(".batch_toggle").bind('click', function(e) {

      // if we are unchecking a box remove the group selections
      if ($(e.currentTarget).attr('checked') != "checked") {
        toggleState($("[data-behavior='batch-edit-select-all']"),'off');    
        toggleState($("[data-behavior='batch-edit-select-page']"),'off');    
        toggleState($("[data-behavior='batch-edit-select-none']"),'off');
        $("#check_all").attr('checked', false);
      }
      // checking a single box see if we need to turn on one of the groups    
      else {
        var n = $(".batch_toggle:checked").length;
        if (n == window.document_list_count) {
            $("#check_all").attr('checked', true);
            if (!window.batch_part_on_other_page) {
              toggleState($("[data-behavior='batch-edit-select-page']"),'on');    
            } else if ((n + window.batch_size_on_other_page) == window.result_set_size){
              toggleState($("[data-behavior='batch-edit-select-all']"),'on');    
            }
        } else {            
            if ((n + window.batch_size_on_other_page) == 0){
              toggleState($("[data-behavior='batch-edit-select-none']"),'on');                 
            }
        }
      }
    });
  
    // hide or show the batch update buttons file selections
    $(".batch_toggle").bind('click', function(e) {
         e.preventDefault();
         toggleButtons();
     });
});

