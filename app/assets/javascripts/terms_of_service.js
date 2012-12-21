$(function () {
    $('#main_upload_start').attr('disabled', true);
    $("#upload_tooltip").hide();
    $("#main_upload_start_span").mousemove(function(e){
       if ( !$('#terms_of_service').is(':checked') ){
           $('#main_upload_start').attr('disabled', true);
        $("#upload_tooltip").show();
        $("#upload_tooltip").css({
            top: (e.clientY+5)+ "px",
            left: (e.clientX+5) + "px"
        });
       } else {
         if (filestoupload > 0) $('#main_upload_start').attr('disabled', false);
         $("#upload_tooltip").hide();
       }
    });
    $("#main_upload_start_span").mouseout(function(e){
        $("#upload_tooltip").hide();
    });
    $("#main_upload_start_span").mouseleave(function(e){
        $("#upload_tooltip").hide();
    });
    $('#terms_of_service').click(function () {
        $('#main_upload_start').attr('disabled', !((this.checked) && (filestoupload > 0)));
        $("#upload_tooltip").hide();
    });
});

