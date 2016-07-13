// Convert a Cyclid job status code to a human readable status
function ji_job_status_to_human(status_id) {
  var statuses = {1: 'New',
                  2: 'Waiting',
                  3: 'Started',
                  4: 'Failing',
                  10: 'Succeeded',
                  11: 'Failed'};
  var status = statuses[status_id];

  var glyphs = {1: 'glyphicon-share-alt',
                2: 'glyphicon-time',
                3: 'glyphicon-refresh',
                4: 'glyphicon-alert',
                10: 'glyphicon-ok',
                11: 'glyphicon-remove'};
  var glyph = glyphs[status_id];

  var labels = {1: 'label-primary',
                2: 'label-primary',
                3: 'label-info',
                4: 'label-warning',
                10: 'label-success',
                11: 'label-danger'};
  var label = labels[status_id];

  return `<span class="label ${label}">
            <span class="glyphicon ${glyph}" aria-hidden="true"></span>&nbsp;${status}
          </span>`
}

// Convert a Cyclid job status code to an indicator
function ji_job_status_to_indicator(status_id) {
  var statuses = {1: 'New',
                  2: 'Waiting',
                  3: 'Started',
                  4: 'Failing',
                  10: 'Succeeded',
                  11: 'Failed'};
  var status = statuses[status_id];

  var glyphs = {1: 'glyphicon-share-alt',
                2: 'glyphicon-time',
                3: 'glyphicon-refresh',
                4: 'glyphicon-alert',
                10: 'glyphicon-ok',
                11: 'glyphicon-remove'};
  var glyph = glyphs[status_id];

  var labels = {1: 'label-primary',
                2: 'label-primary',
                3: 'label-info',
                4: 'label-warning',
                10: 'label-success',
                11: 'label-danger'};
  var label = labels[status_id];

  return `<span class="label ${label}">
            <span class="glyphicon ${glyph}" aria-hidden="true" title="${status}"></span>
          </span>`
}

function ji_calculate_duration(started, ended) {
  var date_started = new Date(started);
  var date_ended = new Date(ended);

  var duration = '';
  if( date_ended > 0 ){
    duration = new Date(date_ended.getTime() - date_started.getTime()).toISOString().substr(11, 8);
  }

  return duration;
}

// Set & show the job log element
function ji_update_log(log_text) {
  // Show the log
  var outer = $('#ji_log_outer');
  outer.removeClass('hidden');

  // Find the current position of the scrollable element, before we update it
  var inner = $('#ji_log_inner')
  var diff = inner.prop('scrollHeight') - (inner.scrollTop() + inner.outerHeight());

  // Update the log
  inner.html(log_text);

  // If the user hasn't scrolled up, scroll to the bottom to show the new log data
  if( diff <= 0 )
    inner.scrollTop(inner.prop('scrollHeight'));
}

// Is the job in a "Failed" or "Succeeded" state?
function ji_job_finished() {
  if( last_status == 10 || last_status == 11 ) {
    return true;
  } else {
    return false;
  }
}

function ji_update_status(job) {
  var status = ji_job_status_to_human(job.status)
  $('#ji_job_status').html(status);

  last_status = job.status;

  // Update the "Waiting" message appropriately
  var waiting = '<h6>Unknown</h6>';
  switch(last_status) {
    case 1:
    case 2:
      waiting = '<h6><i class="fa fa-spinner fa-pulse"></i>&nbsp;Waiting for job to start...</h6>'
      $('#ji_job_waiting').html(waiting);
      $('#ji_job_waiting').removeClass('hidden');
      break;
    case 3:
    case 4:
      waiting = '<h6><i class="fa fa-cog fa-spin"></i>&nbsp;Waiting for job to complete...</h6>';
      $('#ji_job_waiting').html(waiting);
      $('#ji_job_waiting').removeClass('hidden');
      break;
    case 10:
    case 11:
      $('#ji_job_waiting').addClass('hidden');
      break;
  }

  // Update the status indicator, if there is one
  var indicator = ji_job_status_to_indicator(job.status);
  $(`#row${job.job_id} > #status`).html(indicator);
}

// Set & show the job details
function ji_update_details(job) {
  var title = `<a href="${gblLinkbackURL}/job/${job.id}">${job.job_name}&nbsp;<small>v${job.job_version}</small></a>`;
  $('#ji_header').html(title);

  $('#ji_job_id').text(job.id);

  if (job.started) {
    var started = new Date(job.started);
    $('#ji_job_started').text(started.toUTCString());
  }

  if (job.ended) {
    var ended = new Date(job.ended);
    $('#ji_job_ended').text(ended.toUTCString());
  }

  var duration = ji_calculate_duration(job.started, job.ended);
  $('#ji_job_duration').text(duration);

  $('#ji_details').removeClass('hidden');
}

// Update everything: job details, status & log
function ji_update_all(job) {
  ji_update_details(job);
  ji_update_status(job);
  ji_update_log(job.log);
}

function ji_get_failed(xhr) {
  var failure_message = `<p>
                           <h2>Failed to retrieve job</h2><br>
                           <strong>${xhr.status}:</strong> ${xhr.responseText}
                         </p>`
  $('#ji_failure').html(failure_message);

  $('#ji_failure').removeClass('hidden');
}

function ji_update_status_and_check_completion(url, job) {
  if( job.status != last_status ) {
    ji_update_status(job);
  }

  // Did the job end?
  if( ji_job_finished() ){
    // Update the job details so that E.g. the "Ended" time is shown
    api_get(url, gblUsername, ji_update_details, ji_get_failed);

    // Find any timer associated with the job info & remove it
    removeNamedInterval(`watcher${job.job_id}`);
  }
}

function ji_watch_job(url) {
  console.log(`last_status=${last_status}`);

  // Check job status
  var status_url = `${url}/status`;
  api_get(status_url,
          gblUsername,
          function(status) {
            ji_update_status_and_check_completion(url, status);
          },
          ji_get_failed);

  // Update log
  var log_url = `${url}/log`;
  api_get(log_url, gblUsername, function(data) { ji_update_log(data.log); }, ji_get_failed);
}
