function org_show_job() {
  var job_id = $(this).data('job_id');
  var job_info_inner = $('#job-info-inner').html();

  $(`#collapse${job_id}`).html(job_info_inner);

  var url = `${gblOrganizationURL}/jobs/${job_id}`;
  api_get(url, gblUsername, ji_update_all, ji_get_failed);

  console.log(`activating #row${job_id}`);
  // Mark the parent row as active
  $(`#row${job_id}`).addClass('active');

  // Watch the job for status updates
  ji_watcher = setInterval(function() { ji_watch_job(url); }, 3000);
  console.log(`ji_watcher=${ji_watcher}`);
}

function org_hide_job() {
  console.log(`ji_watcher=${ji_watcher}`);
  clearInterval(ji_watcher);

  var job_id = $(this).data('job_id');
  $('#job-info-panel').remove();

  console.log(`de-activating #row${job_id}`);
  // Remove the parent row active highlight
  $(`#row${job_id}`).removeClass('active');
}

function org_add_job(job, append) {
  var accordian = $('#job-accordian tbody');

  var template = $('#job-info').html();
  Mustache.parse(template);

  var date_started = new Date(job.started).toUTCString();
  var date_ended = new Date(job.ended);

  if( date_ended > 0 ){
    date_ended = date_ended.toUTCString();
  } else {
    date_ended = '';
  }

  var data = {id: job.id,
              name: job.job_name,
              started: date_started,
              ended: date_ended,
              status: ji_job_status_to_indicator(job.status)};

  var rendered = Mustache.render(template, data);
  var row = $(rendered);
  row.hide();
  if( append ) {
    accordian.append(row);
  } else {
    accordian.prepend(row);
  }
  row.fadeIn('slow');

  // Add the job ID to the collapsable element so it can associate itself
  // to the correct job
  $(`#collapse${job.id}`).data('job_id', job.id);
}

function org_job_list_failed(xhr) {
  var failure_message = `Failed to retrieve job list<br>
                         <strong>${xhr.status}:</strong> ${xhr.responseText}`;

  failure_message = `List failed: ${xhr.status}`;
  $('#organization_failure').html(failure_message);

  $('#organization_failure').removeClass('hidden');
}

function org_update_job_list(jobs, append) {
  console.log(jobs);

  // Load the list
  var records = jobs.records;
  var length = records.length;
  for( var i = length - 1; i >= 0; i-- ){
    var job = records[i];
    console.log(`job ${i}: ${JSON.stringify(job)}`);

    org_add_job(job, append);
  }

  // Add collapse event handlers to each collapsable element to retrieve
  // & remove the job info
  $('.collapse').each(function(index) {
    $(this).on('hidden.bs.collapse', org_hide_job);
    $(this).on('show.bs.collapse', org_show_job);
  });
  // Ensure any active rows are properly hidden when a new one is shown
  $('.collapse').on('show.bs.collapse', function () {
      $('.collapse.in').collapse('hide');
  });

  // Show or hide the "Load more" button depending on if we're at the end of the list
  if( gblOffset > 0 ) {
    $('#org-load-more').removeClass('hidden');
  } else {
    $('#org-load-more').addClass('hidden');
  }
}

function org_update_counter(total, loaded) {
  var count = `Showing <strong>${total} - ${loaded + 1}</strong> of <strong>${total}</strong>`;
  $('#org-counter').html(count);
}

function org_load_chunk(start) {
  var limit = 100;
  var offset = Math.max(start, limit) - limit;

  // If we're on the last "chunk", there may be less than 'limit' jobs left to
  // load. In that case we need to adjust the limit; we can cheat and use the
  // currently set global offset which happens to be the total remainder of
  // the jobs.
  if( offset == 0){
    limit = gblOffset;
  }
  console.log(`offset=${offset} limit=${limit}`);

  // Remember the current offset
  gblOffset = offset;

  // Update the counter
  org_update_counter(gblTotal, gblOffset);

  var url = `${gblOrganizationURL}/jobs?limit=${limit}&offset=${offset}`;
  api_get(url, gblUsername, function(jobs) { org_update_job_list(jobs, true); }, org_job_list_failed);
}

function org_apply_updates(stats) {
  // Are there any new jobs?
  var count = stats.total - gblTotal;
  if( count > 0 ){
    console.log(`loading ${count} new jobs...`);

    var url = `${gblOrganizationURL}/jobs?limit=${count}&offset=${gblTotal}`;
    api_get(url, gblUsername, function(jobs) { org_update_job_list(jobs, false); }, org_job_list_failed);

    gblTotal = stats.total;

    // Update the counter
    org_update_counter(gblTotal, gblOffset);
  }
}

function org_watch_job_list() {
  // Get the current total number of jobs
  var url = `${gblOrganizationURL}/jobs?stats_only=true`;
  api_get(url, gblUsername, org_apply_updates, org_job_list_failed);
}

function org_initialize_job_list(stats) {
  console.log(stats);

  gblTotal = stats.total;

  // Load the first set of jobs
  org_load_chunk(gblTotal, 100);

  // Watch for any new jobs
  setInterval(org_watch_job_list, 3000);
}
