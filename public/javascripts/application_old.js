// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

//create namespaces

//this represents the html on the page, or the panel.  all of its methods go off the current xml
var panel = function (){

    this.action_menu = $('#actions_wrapper');

    this.child_table = $('#child_and_tag_wrapper').find('table.child');

    this.tags_table = $('#child_and_tag_wrapper').find('table.tags');

    this.thing_name_label = function(){
        return $('#thing_name_wrapper').find('span')
    }
    
    this.parent_thing_name_link = function(){
        return $('#parent_thing_name_wrapper').find('a');
    }

    this.parent_thing_name_label = function(){
        return $('#parent_thing_name_wrapper').find('span');
    }

    this.parent_thing_name_spinner = function(){
        return $('#parent_thing_name_wrapper').find('img');
    }

    this.show_tag_rows = function(){
        $('#child_and_tag_wrapper').find('table.child').hide();
        $('#child_and_tag_wrapper').find('table.tags').show();
    }

    this.clear_tag_rows= function(){
        $('#child_and_tag_wrapper').find('table.tags').children().remove();
    }

    this.add_tag_row = function(key,value){
        $('#child_and_tag_wrapper').find('table.tags').append(
            '<tr class="tag">'
            +'<td class="tag">'
            +'<span class="tag_key">'
            +key
            +'</span><span> : </span>'
            +'<span class="tag_value">'
            +value
            +'<span></span></span></td></tr>'
            )
    }

    this.show_match_rows = function(){
        $('#child_and_tag_wrapper').find('table.tags').hide();
        $('#child_and_tag_wrapper').find('table.child').show();
    }

    this.clear_match_rows= function(){
        $('#child_and_tag_wrapper').find('table.child').children().remove();
    }
    
    this.add_match_row = function(id){
        var row_thing = new thing(id);

        var new_html='<tr class="child">'
        +'<td class="child">'
        +'<span class="nav_link" thing_id="' +row_thing.id + '">'
        +'<a onclick="render_thing(this);return false;" href="#">' + row_thing.name + '</a></span>';

        var row_thing_matches = row_thing.matches()

        //main row section, including show/hide buttons
        if (row_thing_matches.length>0) {
            new_html+=' (' + row_thing_matches.length + '): '
            +'<span class="prompt_link">'
            +'<a onclick="toggle_matches(this);return false;" href="#" style="font-weight:bold;">show</a>'
            +'</span><br/>'
            +'<div thing_id="' + id + '" style="display:none">';
            for (var i=0;i<row_thing_matches.length;i++){
                new_html+=
                '<br/>&nbsp;&nbsp;' + '<span class="nav_link" thing_id="'
                +row_thing_matches[i].id +'">'
                +'<a onclick="render_thing(this);return false;" href="#">'
                +row_thing_matches[i].name + '</a></span><br/>';
            }
            new_html = new_html.slice(0,-2);
            new_html += '</div>';
        }
        new_html+='<br/></td></tr>';
        $('#child_and_tag_wrapper').find('table.child').append(new_html)
    }

    //this renders the current thing on the panel
    this.render = function() {
        //register to server that user is navigating here
        identify(curr_thing().id);

        //update context to new thing
        $('#xml_wrapper').find('context>thing_id').text(curr_thing().id);

        //update header text
        this.thing_name_label().text(curr_thing().name);
        this.parent_thing_name_link().text(curr_thing().parent().name);
        this.parent_thing_name_label().text(curr_thing().parent().name);
        $('#parent_thing_name_wrapper').attr('thing_id',curr_thing().parent().id);

        //refresh children
        this.clear_match_rows();

        var children=curr_thing().children();

        for (var i=0;i<children.length;i++) {
            //collect immediate children for each child path for presentation as separate things
            this.add_match_row(children[i].id)
        }

        //refresh tags

        this.clear_tag_rows();

        var tags = curr_thing().tags();

        if (tags.length>0) {
            $('#show_tags_link').show();
        } else {
            $('#show_tags_link').hide();
        }

        tags.each(function(){
            curr_panel().add_tag_row($(this).find('key').text(),$(this).find('value').text())
        })

        var top_node_id = $('#xml_wrapper').find('context>top_node_thing_id').text();
        //if current is the top_node
        if (curr_thing().parent().id == top_node_id){
            //refresh_with_spinner
            refresh(curr_thing().parent().id);
        }

    }

}

//this represents a particular thing
var thing = function (id){
    this.id = id;

    this.path = function(){
        //find path
        var thing_path = $('#xml_wrapper').find('paths>path>target>thing_id').filter(function(){
            if ($.trim($(this).text()) == id ) {
                return true;
            }else{
                return false;
            }
        }).parent().parent();

        return thing_path;
    }

    this.name = this.path().find('target>name').text();

    this.depth = function(){
        var path = this.path();

        var depth = 1;

        var node_i = '';

        //determine new path's depth by counting the number of nodes
        for (var i=1;i<020;i++)
        {
            if ((i+'').length==1) {
                node_i = '0' + i;
            } else {
                node_i = i;
            }
            depth += path.find('node' + node_i).length==0 ? 0 : 1;
        }

        return depth;
    }

    this.parent = function(){
        var path = this.path();

        var depth = this.depth();

        var parent_depth = depth - 1;

        var node_depth = '';

        if ((parent_depth+'').length==1) {
            node_depth = '0' + parent_depth;
        } else {
            node_depth = parent_depth;
        }

        var thing_parent_id = path.find('node' + node_depth + '>thing_id').text();

        return new thing(thing_parent_id);
    }

    this.children = function(){
        //returns all immediate children of selected thing
        var depth = this.depth();

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

        var child_paths = $('#xml_wrapper').find('paths>path>node' +
            node_depth + '>thing_id:contains(' +id + ')').filter(function(){
            if ($.trim($(this).text()) == id ) {
                //this returns all children that include parent anywhere in their path
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

        var children = new Array();
        child_paths.each(function(){
            children.push(
                new thing($(this).find('target>thing_id').text())
                )
        });
        return children;
    }

    this.matches = function(){
        //returns all immediate children of selected thing
        var depth = this.depth();

        var node_depth = '';

        //find all paths that include target at depth level
        if ((depth+'').length==1) {
            node_depth = '0' + depth;
        } else {
            node_depth = depth;
        }

        var child_matches = $('#xml_wrapper').find('paths>path>node' +
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

        var matches = new Array();
        child_matches.each(function(){
            matches.push(
                new thing($(this).find('target>thing_id').text())
                )
        });
        return matches;
    }

    this.tags = function(){
        var tags = $('#xml_wrapper').find('things>thing').filter(function(){
            if ($(this).find('thing_id').text()==id) {
                return true;
            } else {
                return false;
            }
        }
        ).children().children()
        return tags;
    }

}

//helper methods
//pulls current thing from context
var curr_thing = function(){
    var id = $('#xml_wrapper').find('context>thing_id').text();
    return new thing(id);
}

var render_thing = function(me){
    //update context to this thing
    $('#xml_wrapper').find('context>thing_id').text($(me).parent().attr('thing_id'));
    curr_panel().render();
}

var curr_panel = function(){
    return new panel;
}

//events for page
$(document).ready(function(){
    curr_panel().render();
}
)

//functions for nvigating and upating xml
function toggle_spinner(el) {
    //this assumes you are passing an element with a link inside it.
    //it replaces the link with an unclickable span, or reverse if done already.
    var link = $(el).find('a')

    if (link.is(':hidden')){
        $(el).find('img').hide();
        $(el).find('span').hide();
        link.show();
    } else {
        $(el).find('img').show();
        $(el).find('span').show();
        link.hide();
    }

}

function toggle_tags(me) {
    // hides children, shows tags or vice versa
    if ($(me).text()=='show tags') {
        //if the tags are not yet loaded, load them up
        $(me).text('show members');
        curr_panel().show_tag_rows();
    }else{
        $(me).text('show tags');
        curr_panel().show_match_rows();
    }

}

function toggle_add_panel(me) {
    if ($(me).text() == "Hide Panel") {
        $(me).text("Add");
    } else {
        $(me).text("Hide Panel");
    }
    $('#add_panel').toggle()
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

function toggle_child_spinner() {
    //show spinner for entire child layer
    $('#child_and_tag_wrapper').toggle();
    $('#child_loading_wrapper').toggle();
}

function load_tags(){
    
    var tag_table = $('#child_and_tag_wrapper').find('table.tags');

    tags.find('tag').each(function(){
        curr_panel().add_tag_row()
    })
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
    '<a onclick="load_from_xml(this);return false;" href="#">' + name + '</a></span>';
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

    var child_paths = $('#xml_wrapper').find('paths>path>node' +
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

    var child_matches = $('#xml_wrapper>paths>path>node' +
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

    return child_matches;

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

function rename_thing() {
    var name = prompt('Enter New Name', '');
    if (name == null) return false;
    var id=curr_thing().id;
    //rename display on screen
    $('#thing_name_wrapper').text(name);
    //rename target containing thing
    $('#xml_wrapper').find('paths>path>target>thing_id').filter(function(){
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

function refresh(new_id) {
    
    var prior_id = curr_thing().id;
    
    var term = $('#thing_search').val();

    curr_panel().parent_thing_name_label().show();
    curr_panel().parent_thing_name_spinner().show();
    curr_panel().parent_thing_name_link().hide();

    $.ajax({
        data: 'search=' + term,
        dataType:'script',
        type:'get',
        url:'/things/' + new_id + '/search',
        success: function(){
            if (curr_thing().id == new_id) {
                $('#xml_wrapper').find('context>thing_id').text(prior_id);
                //set context back to prior ID as well to keep sync w server
                identify(prior_id);
            }},
       complete: function(){
            curr_panel().parent_thing_name_label().hide();
            curr_panel().parent_thing_name_spinner().hide();
            curr_panel().parent_thing_name_link().show();
        }
    }); return false;

}

function search(me) {

    toggle_child_spinner();

    var term = $(me).parent().find('input').val();

    $('#xml_wrapper').find('context>search').text(term);
    
    $.ajax({
        data: 'search=' + term,
        dataType:'script',
        type:'get',
        url:'/things/' + curr_thing().id + '/search',
        success: function(){
            toggle_child_spinner();
            curr_panel().render();
        }
    }); return false;
}

