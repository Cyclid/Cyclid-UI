// Perform an authenticated GET to the API server.
function api_get(url, username, success, error) {
  $.ajax({
    type: 'GET',
    url: encodeURI(url),
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

// Perform an authenticated PUT to the API server.
function api_put(url, data, username, success, error) {
  $.ajax({
    type: 'PUT',
    url: encodeURI(url),
    data: JSON.stringify(data),
    contentType: 'application/json',
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
