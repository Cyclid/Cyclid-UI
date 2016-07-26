function user_show_error(msg){
  $('#user_failure > #error_message').html(msg);
  $('#user_failure').removeClass('hidden');
}

function user_get_failed(xhr){
  var failure_message = `Failed to retrieve user details<br>
                         <strong>${xhr.status}:</strong> ${xhr.responseText}`;
  failure_message = `Get failed: ${xhr.status}`;

  user_show_error(failure_message);
}

function user_update_details(user){
  console.log(JSON.stringify(user));

  $('#user_heading').text(user.username);

  name = user.name || user.username;
  $('#user_name').text(name);
  $('#user_email').text(user.email);

  var length = user.organizations.length;
  if( length > 0 ){
    for(var i=0; i < length; i++){
      var org = user.organizations[i];
      var org_link = `<a href="#" id="user_config_${org}" download="${org}"><i class="fa fa-download" aria-hidden="true"></i>&nbsp;${org}</a><br>`;
      $('#user_org_list').append(org_link);

      var config_org = $(`#user_config_${org}`);
      config_org.data('org', org);
      config_org.click(function(e) {
        var org = $(this).data('org');

        var config = `server: ${gblAPIURL}\n` +
                     `organization: ${org}\n` +
                     `username: ${user.username}\n` +
                     `secret: `;  

        console.log(`${org} was clicked: ${config}`);

        this.href = "data:application/x-yaml," + encodeURIComponent(config);
      });
    }
  } else {
    $('#user_org_list').append('<em>None</em>');
  }

  $('#user_info').removeClass('hidden');
}

function user_password_secret_toggle() {
  var secret = $('#user_password_secret');

  // Toggle the disabled state on the 'secret' input; generate a new secret
  // if one is required.
  secret.prop('disabled', function(i, v) {
    var key = secret.val();
    if(v && !key){
      // The key does not need to be cryptographically strong; just suitably
      // unique
      var key1 = Math.random().toString(36).substr(2,34);
      var key2 = Math.random().toString(36).substr(2,34);

      key = $.md5(key1 + key2);
      secret.val(key);
    }
    return !v;
  });
}

function user_password_form_reset() {
  $('#user_password_failure').addClass('hidden');
  $('#user_password_password_1').val('');
  $('#user_password_password_2').val('');
  $('#user_password_reset_signing').removeAttr('checked');
  $('#user_password_secret').val('');
  $('#user_password_secret').prop('disabled', true);
}

function user_password_update_failed(xhr){
  var failure_message = `Failed to change password<br>
                         <strong>${xhr.status}:</strong> ${xhr.responseText}`;
  failure_message = `Put failed: ${xhr.status}`;

  user_show_error(failure_message);
}

function user_password_validate_submit() {
  var password_1 = $('#user_password_password_1').val();
  var password_2 = $('#user_password_password_2').val();
  var change_secret = $('#user_password_reset_signing').is(':checked');
  var secret = $('#user_password_secret').val();

  console.log(`1=${password_1} 2=${password_2} change_secret=${change_secret} secret=${secret}`);

  var post_data = {};

  // Check that the password is valid
  if(password_1 == '' || password_2 == '') {
    // Show an error message
    console.log('password is empty');
    $('#user_password_error_message').text('Password cannot be empty');
    $('#user_password_failure').removeClass('hidden');

    return false;
  } else if(password_1 != password_2) {
    // Show an error message
    console.log('passwords do not match');
    $('#user_password_error_message').text('Passwords do not match');
    $('#user_password_failure').removeClass('hidden');

    return false;
  } else {
    post_data['new_password'] = password_1;
  }

  if(change_secret){
    if( secret == '' ){
      // Show an error message
      console.log('secret is empty');
      $('#user_password_error_message').text('Client token cannot be empty');
      $('#user_password_failure').removeClass('hidden');

      return false;
    } else {
      post_data['secret'] = secret;
    }
  }

  console.log(`url=${gblUserURL} data=${JSON.stringify(post_data)}`);

  // Update the authentication details
  api_put(gblUserURL, post_data, gblUsername, null, user_password_update_failed);
}

$(document).ready(function() {
  $('#user_password_reset_signing').click(user_password_secret_toggle);

  // Reset the password form every time it's opened
  $('#user_password_modal').on('show.bs.modal', user_password_form_reset);

  // Validate & submit the password form
  $('#user_password_ok').click(user_password_validate_submit);
});
