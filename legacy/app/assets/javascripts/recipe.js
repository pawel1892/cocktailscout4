$( document ).on('turbolinks:load', function() {
    $(".recipe_favorite").click(function() {
        var node_id = $(this).attr('id');
        var recipe_id = node_id.split('_')[2];
        $.ajax({
            type: "POST",
            url: '/favorite_recipe_toggle/?recipe_id=' + recipe_id,
            success: function() {
                $( "#" + node_id ).toggleClass("faved");
            }
        })
    })

});
