// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function browse(me)
{
    //me here identifies the clicked anchor, whose parent will have property thing_id
    var id = $(me).parent().attr('thing_id');

    //register to server that user is navigating here
    identify(id);

    var thing_path = get_thing_path(id);
    var parent_thing_path = get_parent_thing_path(id);

    var parent_thing_name_wrapper = $('#parent_thing_name_wrapper');
    //update header text
    $('#thing_name_wrapper').text(thing_path.find('target>name').text());
    parent_thing_name_wrapper.find('a').text(parent_thing_path.find('target>name').text());
    parent_thing_name_wrapper.attr('thing_id',parent_thing_path.find('target>thing_id').text());

    //update context to new thing
    $('#xml_wrapper>context>thing_id').text(id);

    //determine if thing has tags; if so, show tag option
    var tags = $('#xml_wrapper>things>thing').filter(function(){
        if ($(this).find('thing_id').text()==id) {
            return true;
        } else {
            return false;
        }
    }
    )

    if (tags.find('tags').length>0) {
        //show tag panel and clear out actual tag container for posible load
        $('#panel_wrapper').show();
        $('#child_and_tag_wrapper>div.tags_container>table>tbody').remove();
    }

    //take the paths immediately below and group all paths beneath them
    var child_paths = get_child_paths(id);

    var new_html = '';

    child_paths.each(function(){
        //collect immediate children for each child path for presentation as separate things
        var child_id = $(this).find('target>thing_id').text();
        var child_name = $(this).find('target>name').text();

        //searching
        new_html+='<tr class="child">'+
        '<td class="child">'+
        get_thing_link(child_id,child_name);

        var child_matches = get_child_matches(child_id);
        if (child_matches.length>0) {
            new_html+=' (' + child_matches.length + '): ' +
            '<span class="prompt_link">' +
            '<a onclick="toggle_matches(this);return false;" href="#">show</a>' +
            '</span>' +
            '<div thing_id="' + child_id + '" style="display:none">'
            child_matches.each(function(){
                var next_child_id = $(this).find('target>thing_id').text();
                var next_child_name = $(this).find('target>name').text();

                new_html+='&nbsp;&nbsp;' + get_thing_link(next_child_id,next_child_name) + '<br/>';
            })
            new_html = new_html.slice(0,-2);
            new_html += '</div>';
        }
        new_html+='</td></tr>';
    }
    )

    //replace table html with new contents
    $().find('table.child').html(new_html);

    var top_node = $('#xml_wrapper>context>top_node_thing_id');
    var parent_thing = parent_thing_path.find('target>thing_id');
    //if current is the top_node
    if (id == top_node.text()){
        //unless parent is at the top
        if (parent_thing.length!=0) {
            //refresh_with_spinner
            refresh_with_spinner(parent_thing.text(),parent_thing_name_wrapper);
        //set next parent as the top node
        }
    }
}

function toggle_spinner(el) {
    //this assumes you are passing an element with a link inside it.
    //it replaces the link with an unclickable span, or reverse if done already.
    var link = $(el).find('a')
    var link_text = link.text();

    if (link.is(':hidden')){
        $(el).find('img').remove();
        $(el).find('span').remove();
        link.show();
    } else {
        $(el).append('<img src="images\\small_spinner.gif">' +
            '<span class="small_link_disabled">' +link_text + '</span>');
        link.hide();
    }

}

function load_tags(){
    var tags = $('#xml_wrapper>things>thing').filter(function(){
        if ($(this).find('thing_id').text()==$('#xml_wrapper>context>thing_id').text()){
            return true;
        } else {
            return false;
        }
    }).find('tags');

    var tag_table = $('#child_and_tag_wrapper>div.tags_container>table');

    tags.find('tag').each(function(){
        tag_table.append(
            '<tr class="tag">'+
            '<td class="tag">'+
            '<span class="tag_key">'+
            $(this).find('key').text()+
            '</span><span> : </span>'+
            '<span class="tag_value">'+
            $(this).find('value').text()+
            '<span></span></span></td></tr>'
            )
    })
}

function toggle_tags(me) {
    // hides children, shows tags or vice versa
    var tag_container = $('#child_and_tag_wrapper>div.tags_container');
    var child_container = $('#child_and_tag_wrapper>div.child_container')
    if ($(me).text()=='show tags') {
        //if the tags are not yet loaded, load them up
        if (tag_container.find('table>tbody').length==0) {
            load_tags()
        }
        $(me).text('show members');
        child_container.hide();
        tag_container.show();
    }else{
        $(me).text('show tags');
        tag_container.hide();
        child_container.show();
    }

}

function get_child_row(id,name) {

    var next_child_paths = get_child_paths(id);
    var child_html =  '<tr class="child" thing_id="' +id + '">'+
    '<td class="child" thing_id="' +id + '">'+
    '<div class="child" thing_id="' +id + '">'+
    '<a onclick="delete(this);return false;" href="#">[d]</a>'+
    '<a onclick="cut(this);return false;" href="#">[x]</a>'+
    get_thing_link(id,name);

    if (next_child_paths.length>0) {
        child_html+=' (' + next_child_paths.length + ' thing';
        if (next_child_paths.length>1) {
            child_html+='s';
        }
        child_html+=' )';
    }


    child_html+='</div></td></tr>';
    return child_html;
}

function get_thing_link(id,name) {
    return '<span class="nav_link" thing_id="' +id + '">'+
    '<a onclick="browse(this);return false;" href="#">' + name + '</a></span>';
}

function get_parent_thing_path(id) {
    var path = get_thing_path(id);

    var depth = get_thing_depth(id);

    var parent_depth = depth - 1;

    var node_depth = '';

    if ((parent_depth+'').length==1) {
        node_depth = '0' + parent_depth;
    } else {
        node_depth = parent_depth;
    }

    var thing_parent_id = path.find('node' + node_depth + '>thing_id').text();

    return get_thing_path(thing_parent_id);

}

function get_child_paths(id) {
    //returns all immediate children of selected thing
    var depth = get_thing_depth(id);

    var node_depth = '';

    //find all paths that include target at depth level
    if ((depth+'').length==1) {
        node_depth = '0' + depth;
    } else {
        node_depth = depth;
    }

    var child_depth = depth + 1;

    var child_node_depth = '';

    if ((child_depth+'').length==1) {
        child_node_depth = '0' + child_depth;
    } else {
        child_node_depth = child_depth;
    }

    var child_paths = $('#xml_wrapper>paths>path>node' +
        node_depth + '>thing_id:contains(' +id + ')').filter(function(){
        if ($.trim($(this).text()) == id ) {
            //this returns all children than include parent anywhere in their path
            return true;
        }else{
            return false;
        }
    }).parent().parent().filter(function(){
        if ($(this).find('node' + child_node_depth).length == 0 ) {
            //this filters them by immediate children
            return true;
        }else{
            return false;
        }
    });

    return child_paths;

}

function get_child_matches(id) {
    //returns all immediate children of selected thing
    var depth = get_thing_depth(id);

    var node_depth = '';

    //find all paths that include target at depth level
    if ((depth+'').length==1) {
        node_depth = '0' + depth;
    } else {
        node_depth = depth;
    }

    var child_paths = $('#xml_wrapper>paths>path>node' +
        node_depth + '>thing_id:contains(' +id + ')').filter(function(){
        if ($.trim($(this).text()) == id ) {
            //this returns all children than include parent anywhere in their path
            return true;
        }else{
            return false;
        }
    }).parent().parent().filter(function(){
        if ($(this).find('target>nonmatch').length == 0 ) {
            //make sure it's not a nonmatch
            return true;
        }else{
            return false;
        }
    });

    return child_paths;

}

function get_thing_path(id) {
    //find path
    var thing_path = $('#xml_wrapper>paths>path>target>thing_id:contains(' +id + ')').filter(function(){
        if ($.trim($(this).text()) == id ) {
            return true;
        }else{
            return false;
        }
    }).parent().parent();

    return thing_path;
}

function identify(id) {
    $.ajax({
        dataType:'script',
        type:'post',
        url:'/things/' +id + '/identify'
    });
}

function refresh_with_spinner(id,el) {
    //toggle spinner
    toggle_spinner(el);
    //loads xml into the specified level
    $.ajax({
        data: 'display=false',
        dataType:'script',
        type:'get',
        url:'/things/' +id + '/search',
        success: function() {
            toggle_spinner(el);
        }
    });
    return false;
}

function get_thing_depth(id){

    var path = get_thing_path(id);

    var depth = 1;

    var node_i = '';
    
    //determine new path's depth by counting the number of nodes
    for (i=1;i<020;i++)
    {
        if ((i+'').length==1) {
            node_i = '0' + i;
        } else {
            node_i = i;
        }
        depth += path.find('node' + node_i).length;
    }

    return depth;

}

function rename_thing() {
    var name = prompt('Enter New Name', '');
    if (name == null) return;
    var id=$('#xml_wrapper>context>thing_id').text();
    //rename display on screen
    $('#thing_name_wrapper').text(name);
    //rename target containing thing
    $('target>thing_id:contains(' +id + ')').filter(function(){
        if ($.trim($(this).text()) == id ) {
            return true;
        }else{
            return false;
        }
    }).parent().each(function(){
        $(this).find('name').text(name);
    }
    );

    return add_tag(id,'name',name);
}

function add_tag(id,key,value) {
    $.ajax({
        data: 'key=' + escape(key) + '&value=' + escape(value),
        dataType:'script',
        type:'post',
        url:'/things/' +id + '/add_tag'
    });
    return false;
}

function delete_tag(me) {

    var key = '';
    var value = '';
    var id = get_context_id();
    //determine if the tag in question is a child or a simple tag
    if ($(me).parent().attr('class')=='child') {
        //child
        key = 'has';
        value = $(me).parent().attr('thing_id');
    } else {
        //tag
        key = $(me).parent().parent().find('td.tag_key').text();
        value = $(me).parent().parent().find('td.tag_value').text();
    }
    $.ajax({
        data: 'key=' + escape(key) + '&value=' + escape(value),
        dataType:'script',
        type:'post',
        url:'/things/' +id + '/delete_tag'
    });
    return false;
}

function get_context_id(){
    return $('#xml_wrapper>context>thing_id').text();
}

function cut(me) {
    var thing_id = $(me).parent().parent().attr('thing_id');
    var name = $(me).parent().find('span>a').text();
    var id=$('#xml_wrapper>context>thing_id').text();
    var clip_member_table = $('#clip_member_wrapper>table');
    //check to ensure that this thing has not already been entered
    var is_in = false;
    clip_member_table.find('tr').each(function(){
        if ($(this).attr('thing_id')==thing_id){
            is_in = true;
        }
    });
    if (is_in == false){
        clip_member_table.append(get_clip_row(thing_id,name));
        clip(id,'cut',thing_id);
    }

}

function cancel(me) {
    var thing_id = $(me).parent().parent().attr('thing_id');
    var id=$('#xml_wrapper>context>thing_id').text();
    var clip_member_table = $('#clip_member_wrapper>table');
    //find the row with the thing and delete it
    clip_member_table.find('tr').each(function(){
        if ($(this).attr('thing_id')==thing_id){
            $(this).remove();
        }
    });
    //to server
    clip(id,'cancel',thing_id);
}

function get_clip_row(id,name) {
    return '<tr class="clip_members" thing_id="' +id + '">'+
    '<td class="clip_members" thing_id="' +id + '">'+
    '<div class="clip_members" thing_id="' +id + '">'+
    '<a onclick="paste(this);return false;" href="#">Paste</a>'+
    '<span><a onclick="browse(this);return false;" href="#"> ' +name + ' </a></span>'+
    '<a onclick="cancel(this);return false;" href="#">Cancel</a>'+
    '</div></td></tr>'
}

function clip(id,op,thing_id) {
    $.ajax({
        data: 'op=' + op + '&thing_id=' + thing_id,
        dataType:'script',
        type:'post',
        url:'/things/' +id + '/clip'
    });
    return false;
}

function toggle_child_spinner() {
    //show spinner for entire child layer
    $('#child_and_tag_wrapper').toggle();
    $('#child_loading_wrapper').toggle();

}

function search(me) {

    toggle_child_spinner();

    var id = $('#xml_wrapper>context>thing_id').text();

    var term = $(me).find('input').val();

    $.ajax({
        data: 'search=' + term,
        dataType:'script',
        type:'get',
        url:'/things/' + id + '/search',
        success: function(){
            toggle_child_spinner();
        }
    }); return false;
}


function toggle_matches(me){
    var child_div = $(me).parent().parent().find('div');
    if ($(me).text()=='show') {
        $(me).text('hide');
        child_div.show();
    } else {
        $(me).text('show');
        child_div.hide();
    }
}
