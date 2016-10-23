/* Submit the current configuration data to the API */
function config_save(){
  console.log('saving config...');

  event.preventDefault();

  var form_elements = new Array();
  $('#config_form :input').each(
    function(){
      form_elements.push($(this));
    }
  );

  var length = form_elements.length;
  var config_data = new Object();
  for(var i=0; i < length; i++){
    var input = form_elements[i];
    console.log(input);

    if(input.attr('type') == 'text' || input.attr('type') == 'password') {
      var name = input.attr('name');
      var value = input.val();
      var config_value = value == '' ? null : value;

      console.log(`${name}=${config_value}`);
      config_data[name] = config_value;
    } 
  }
  console.log(`configuration is ${JSON.stringify(config_data)}`);

  /* Write the configuration data to the API */
  var plugin_name = $('#config_form').data('plugin_name');
  var plugin_type = $('#config_form').data('plugin_type');

  var url = `${gblOrgUrl}/configs/${plugin_type}/${plugin_name}`;
  api_put(url, config_data, gblUsername, null, config_set_failed);
}

/* Add a "string" schema element to the configuration data form */
function config_append_string(elem, schema, config){
  var default_data = schema.default == null ? '' : schema.default;
  var config_data = config == undefined ? default_data : config;
  var row = `<div class="form-group"><label for="${schema.name}">${schema.description}</label><input type="text" class="form-control" name="${schema.name}" value="${config_data}"></div>`

  elem.append(row);
}

/* Add a "password" schema element to the configuration data form */
function config_append_password(elem, schema, config){
  var default_data = schema.default == null ? '' : schema.default;
  var config_data = config == undefined ? default_data : config;
  var row = `<div class="form-group"><label for="${schema.name}">${schema.description}</label><input type="password" class="form-control" name="${schema.name}" value="${config_data}"></div>`

  elem.append(row);
}

/* Add a button as a link to a URL to the configuration data form */
function config_append_link(elem, schema, url){
  var row = `<div class="form-group"><a href="${url}" id="${schema.name}" class="btn btn-default" role="button">${schema.description}</a></div>`

  elem.append(row);
}

/* Add a "link-relative" (I.e. a link relative to the plugin API) schema element to the configuration data form */
function config_append_link_relative(elem, schema, config){
  var plugin_name = $('#config_form').data('plugin_name');
  var url = `${gblOrgUrl}/plugins/${plugin_name}${schema.default}`;

  config_append_link(elem, schema, url);
}

/* Add a "link-absolute" (I.e. a link to a fully qualified URL) schema element to the configuration data form */
function config_append_link_absolute(elem, schema, config){
  config_append_link(elem, schema, config);
}

function config_update_plugin(data) {
  console.log(JSON.stringify(data));

  var schema = data.schema;
  var config = data.config;
  var form = $('#config_form');

  /* Clear any existing form elements */
  form.empty();

  /* Walk the schema and insert each element */
  var length = schema.length;
  for(var i=0; i < length; i++){
    var item_schema = schema[i];
    var item_config = config[item_schema.name];

    switch(item_schema.type){
      case 'string': {
        console.log(`${item_schema.name} is a string`);
        config_append_string(form, item_schema, item_config);
        break;
      }
      case 'password': {
        console.log(`${item_schema.name} is a password`);
        config_append_password(form, item_schema, item_config);
        break;
      }
      case 'integer': {
        console.log(`${item_schema.name} is an integer`);
        config_append_string(form, item_schema, item_config);
        break;
      }
      case 'hash-list': {
        console.log(`${item_schema.name} is a hash-list`);
        break;
      }
      case 'link-relative': {
        console.log(`${item_schema.name} is a link-relative`);
        config_append_link_relative(form, item_schema, item_config);
        break;
      }
      default: {
        console.log(`don't know what ${item_schema.name} is`);
        break;
      }
    }
  }

  /* Add the "Save" button */
  form.append('<input type="submit" class="btn btn-success" onclick="config_save()" value="Save">');
}

function config_select(plugin_type, plugin_name) {
  console.log(`select ${plugin_type}/${plugin_name}`);

  var form = $('#config_form');
  form.data('plugin_type', plugin_type);
  form.data('plugin_name', plugin_name);

  $('#config_plugin_name').html(plugin_name)

  var url = `${gblOrgUrl}/configs/${plugin_type}/${plugin_name}`;
  api_get(url, gblUsername, config_update_plugin, config_get_failed);
}

function config_get_failed(xhr) {
  console.log("couldn't get config data");
}

function config_set_failed(xhr, status, error) {
  console.log(`couldn't set config data: status=${status} error=${error} code=${JSON.stringify(xhr.statusCode())}`);
}

function config_update_list(data) {
  console.log(JSON.stringify(data));

  var length = data.length;
  for(var i=0; i < length; i++ ){
    var plugin = data[i];
    var type = plugin.type
    var name = plugin.name

    var item = `<a href="#" class="list-group-item list-group-item-action" style="text-transform:capitalize;" onclick="config_select('${type}', '${name}')">${name}</a>`
    $('#plugin-list').append(item);
  }
}
