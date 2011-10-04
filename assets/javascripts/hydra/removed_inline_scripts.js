// This is tied to HYDRUS-150
// Dumping ground for inline javascript that has been removed from view templates & partials

// Make sure to indicate what file the scripts came from

/*
Pulled from _edit_partials/default.html.erb

  <script type="text/javascript">
    //<![CDATA[
    $(document).ready(function() {
      $(document).catalogEdit();
      $("a.inline").fancybox({
              'hideOnContentClick': true,
              'autoDimensions' : false
          });
    });
    //]]>
  </script>
*/


/*
From file_assets/index.html.haml

:javascript
    $(document).ready(function() {
      $("#file_assets  .editable-container").hydraTextField();
    });
    
:javascript
  $(document).ready(function() {
    $("#file_assets  .editable-container").hydraTextField();
  });
    
*/

/* 
From generic_contents/_edit.html.erb

<script type="text/javascript">
  $(document).ready(function() {
    $(document).catalogEdit();
  });
</script>

*/

/*
From generic_images/_edit.html.erb
<% if files = params[:files] %>
  <script type="text/javascript">
    $(document).ready(function() {
      $("#accordion").accordion({active: 1});
    });
  </script>
<% end %>

<% extra_head_content << capture do %>
  <script type="text/javascript">
    $(document).ready(function() {
      $(document).catalogEdit();
    });
  </script>
<% end %>

*/

/*
From vendor/plugins/hydrangea_datasets/apps/hydrangea_datasets/view/_edit.html.erb
<% if params[:files] %>
  <script type="text/javascript">
    $(document).ready(function() {
      $("#accordion").accordion({active: 2});
    });
  </script>
<% end %>

<% extra_head_content << capture do %>
  <script type="text/javascript">
    $(document).ready(function() {
      $(document).catalogEdit();
    });
  </script>
<% end %>



From vendor/plugins/hydrangea_datasets/apps/hydrangea_datasets/view/_show.html.erb

<% if params[:files] %>
  <script type="text/javascript">
    $(document).ready(function() {
      $("#accordion").accordion({active: 2});
    });
  </script>
<% end %>

*/


/*
From vendor plugins/hydrangea_articles/apps/hydrangea_articles/views/_edit.html.erb
<% if params[:files] %>
  <script type="text/javascript">
    $(document).ready(function() {
      $("#accordion").accordion({active: 2});
    });
  </script>
<% end %>

<% extra_head_content << capture do %>
  <script type="text/javascript">
    $(document).ready(function() {
      $(document).catalogEdit();
    });
  </script>
<% end %>
*/

/*
From vendor/plugins/admin_policy_objects/apps/admin_policy_objects/views/edit.html.erb
<% if files = params[:files] %>
  <script type="text/javascript">
    $(document).ready(function() {
      $("#accordion").accordion({active: 1});
    });
  </script>
<% end %>

<% extra_head_content << capture do %>
  <script type="text/javascript">
    $(document).ready(function() {
      $(document).catalogEdit();
    });
  </script>
<% end %>
*/

/*
From vendor/plugins/admin_policy_objects/app/admin_policy_objects/views/show.html.erb
<% if params[:files] %>
  <script type="text/javascript">
    $(document).ready(function() {
      $("#accordion").accordion({active: 1});
    });
  </script>
<% end %>

*/

/*
From vendor/plugins/dor_objects/app/views/dor_objects/_edit.html.erb
<% if files = params[:files] %>
  <script type="text/javascript">
    $(document).ready(function() {
      $("#accordion").accordion({active: 1});
    });
  </script>
<% end %>

<% extra_head_content << capture do %>
  <script type="text/javascript">
    $(document).ready(function() {
      $(document).catalogEdit();
    });
  </script>
<% end %>

*/

// Make sure to indicate what file the scripts came from