function user_get_failed(xhr){
  var failure_message = `Failed to retrieve user detials<br>
                         <strong>${xhr.status}:</strong> ${xhr.responseText}`;

  failure_message = `Get failed: ${xhr.status}`;
  $('#user_failure > #error_message').html(failure_message);

  $('#user_failure').removeClass('hidden');
}

function user_update_details(user){
  $('#user_dump').html(JSON.stringify(user));

  $('#user_email').text(user.email);

  var length = user.organizations.length;
  if( length > 0 ){
    for(var i=0; i < length; i++){
      $('#user_org_list').append(`${user.organizations[i]}<br>`);
    }
  } else {
    $('#user_org_list').append('<em>None</em>');
  }

  // Obtain the Gravatar profile image, if one exists
  var hash = $.md5(user.email.trim().toLowerCase());
  console.log(`hash=${hash}`);

  var gravatar_url = `https://www.gravatar.com/avatar/${hash}?s=100&d=identicon&r=g`;
  console.log(`gravatar_url=${gravatar_url}`);
  $('#user_avatar').html(`<img src="${gravatar_url}" style="width:100px;height:100px;">`);

  $('#user_info').removeClass('hidden');
}
