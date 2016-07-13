function org_show_job() {
  var job_id = $(this).data('job_id');
  var job_info_inner = $('#job-info-inner').html();

  $(`#collapse${job_id}`).html(job_info_inner);

  var url = `${gblOrganizationURL}/jobs/${job_id}`;
  api_get(url, gblUsername, ji_update_all, ji_get_failed);

  // Watch the job for status updates
  addNamedInterval(`watcher${job_id}`, function() { ji_watch_job(url); }, 3000);

  // Mark the parent row as active
  $(`#row${job_id}`).addClass('active');
}

function org_hide_job() {
  var job_id = $(this).data('job_id');
  $(`#collapse${job_id} > #job-info-panel`).remove();

  // Clear any watchers
  removeNamedInterval(`watcher${job_id}`);

  // Remove the parent row active highlight
  $(`#row${job_id}`).removeClass('active');
}

function org_add_job(job, append) {
  var accordian = $('#job-accordian tbody');

  var template = $('#job-info').html();
  Mustache.parse(template);

  var duration = ji_calculate_duration(job.started, job.ended);

  var data = {id: job.id,
              name: job.job_name,
              started: new Date(job.started).toUTCString(),
              duration: duration,
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

  // If the job is active, add it to the active list
  if( window.active_jobs == undefined )
    window.active_jobs = [];

  if( ji_job_active(job.status) ){
    var active = {job_id: job.id, status: job.status};
    window.active_jobs.push(active);
  }
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

function org_apply_indicator_update(job, active, idx) {
  console.log(`callback for job #${active.job_id}: old status is ${active.status}, new status is ${job.status}`);
  if( job.status == 0 ){
    console.log(`got a 0 status: ${JSON.stringify(job)}`);
  }

  if( job.status != active.status ){
    console.log(`job #${job.job_id} status changed from ${active.status} to ${job.status}`);

    var indicator = ji_job_status_to_indicator(job.status);
    $(`#row${job.job_id} > #status`).html(indicator);

    // Did the job finish? If so we can stop watching it
    if( ji_job_finished(job.status) ) {
      console.log(`job #${job.job_id} has finished; removing from active_jobs at position ${idx}`);
      window.active_jobs.splice(idx, 1);
    } else {
      // Remember the current status
      active.status = job.status;
      window.active_jobs[idx] = active;
    }
  }
}

function org_watch_job_list() {
  // Get the current total number of jobs
  var url = `${gblOrganizationURL}/jobs?stats_only=true`;
  api_get(url, gblUsername, org_apply_updates, org_job_list_failed);

  // Check the status of any current jobs
  var length = window.active_jobs.length;
  for( var idx = 0; idx < length; idx++ ){
    var active = window.active_jobs[idx];

    console.log(`checking status of job #${active.job_id}: current status is ${active.status}`);

    (function(a, i){
    url = `${gblOrganizationURL}/jobs/${active.job_id}/status`
    api_get(url,
            gblUsername,
            function(job) { org_apply_indicator_update(job, a, i); },
            org_job_list_failed);
    })(active, idx);
  }
}

function org_initialize_job_list(stats) {
  console.log(stats);

  gblTotal = stats.total;

  // Load the first set of jobs
  org_load_chunk(gblTotal, 100);

  // Watch for any new jobs
  setInterval(org_watch_job_list, 3000);
}
