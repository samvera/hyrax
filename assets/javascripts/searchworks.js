$(document).ready(function() {
          var pop_up_img = $("#__GBS_Button0");
          pop_up_img.remove();
          $('#cover_container').append(pop_up_img);
 $('#facets ul, #advanced_search_facets ul').each(function(){
   var ul = $(this);
   // find all ul's that don't have any span descendants with a class of "selected"
   if($('span.selected', ul).length == 0 && ul.attr("id") != "related_subjects"  ){
        // hide it
        if (ul.prev('h3').attr("class") != "facet_selected"){
          ul.hide();
        }
        // attach the toggle behavior to the h3 tag
        $('h3', ul.parent()).click(function(){
           $(this).toggleClass("facet_selected");
           $(this).next('ul').slideToggle();
       });
   }else{
     ul.prev('h3').attr("class","facet_selected");
   }
 });
 
 // Help Text
 $(".help_text_link").each(function(){
   $(this).click(function(){
     $("#" + $(this).attr("name")).toggle();
   });
 });
 
 // 856's
 $('#more_link').click(function(){
   $('#more_link').toggle();
   $('#less_link').toggle();
   $('li .more').each(function(){
     $(this).toggle();
   });
   return false;
 });
 $('#less_link').click(function(){
   $('#less_link').toggle();
   $('#more_link').toggle();
   $('li .more').each(function(){
      $(this).toggle();
    });
    return false;
 });
 
 // Online H2, needs reworking later
 if( $(".record_url").length > 0 || $("#gbs_preview2").attr("href") != "" || $("ul.online").length > 0){
   if($("#online_h2").css("display") == 'none'){
     $("#online_h2").toggle();
   }   
 }
 
 // Search button
 $('#spec_search').toggle();
 $('#hidden_qt').attr("name","qt");
 $('#hidden_qt').attr("id","qt");
 $('#search_button').click(function(){
   $('#search_links').toggle();
 });
 
 $('#spec_search a').each(function(){
   $(this).click(function(){
     if($(this).attr("id") != 'seach_button_link'){
       $('#qt').attr('value',$(this).attr("class"));
       $('#search_links').toggle();
       if($(this).text() == 'Everything'){
         $('#seach_button_link').text("SEARCH");
       }else{
         $('#seach_button_link').text("Search " + $(this).text());
       }
     }
     $('form:first').trigger("submit");
     return false;
   });
 });
 
 
 // Send To Button
 $('#send_to_div').toggle();
 $('#send_to_link').mouseover(function(){
   if($('#send_to_div').css("display") == 'none'){
     $('#send_to_div').toggle();
   }
 });
 $('#send_to_div').mouseleave(function(){
   $('#send_to_div').toggle();
 });
 $('#send_to_div a').each(function(){
   $(this).click(function(){
     if($('#send_to_div').css("display") == 'none') {
       $('#send_to_div').toggle();
     }
   });
 });
 $('#send_to_div br').each(function(){
   $(this).toggle();
 });
});