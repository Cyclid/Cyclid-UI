// Perform an authenticated GET to the API server.
function api_get(url, username, success, error) {
  $.ajax({
    url: url,
    dataType: 'json',
    crossDomain: true,
    beforeSend: function(xhr) {
      var token = Cookies.get('cyclid.token');
      var authorization = `Token ${username}:${token}`
      xhr.setRequestHeader('Authorization', authorization);
    },
    success: success,
    error: error
  });
}
