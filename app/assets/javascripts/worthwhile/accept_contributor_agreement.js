(function($) {
  $("a[rel=popover]").popover({ html : true, trigger: "hover" });
  $("a[rel=popover]").click(function() { return false;});

  $('#accept_contributor_agreement').each(function(){
    $.fn.disableAgreeButton = function(element) {
      var $submit_button = $('input.require-contributor-agreement');
      $submit_button.prop("disabled", !element.checked);
    };
    $.fn.disableAgreeButton(this);
    $(this).on('change', function(){
      $.fn.disableAgreeButton(this);
    });
  });
})(jQuery);
