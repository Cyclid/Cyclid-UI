function org_show_job() {
  var job_id = $(this).data('job_id');
  var job_info_inner = $('#job-info-inner').html();

  $(`#collapse${job_id}`).html(job_info_inner);

  var url = `${gblOrganizationURL}/jobs/${job_id}`;
  api_get(url, gblUsername, ji_update_all, ji_get_failed);

  // Watch the job for status updates
  (function(j, u) {
    addNamedInterval(`watcher${j}`,
                      function() { ji_watch_job(u); },
                      3000);
  })(job_id, url);

  // Mark the parent row as active
  $(`#row${job_id}`).addClass('active');
}

function org_hide_job() {
  var job_id = $(this).data('job_id');

  // Clear any watchers
  removeNamedInterval(`watcher${job_id}`);

  // Remove the job info panel
  $(`#collapse${job_id} > #job-info-panel`).remove();

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
  $('#organization_failure > #error_message').html(failure_message);

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
  console.log(`offset=${offset} limit=${limit} gblOffset=${gblOffset}`);

  // Remember the current offset
  gblOffset = offset;

  // Update the counter
  org_update_counter(gblTotal, gblOffset);

  var url = `${gblOrganizationURL}/jobs?limit=${limit}&offset=${offset}`;

  // Apply any search terms
  var search = window.search;
  if( ! $.isEmptyObject(search) ){
    for( var s in search ){
      url += `&${s}=${search[s]}`;
    }
  }
  console.log(`chunk url=${url}`);

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

  // Apply any search terms
  var search = window.search;
  if( ! $.isEmptyObject(search) ){
    for( var s in search ){
      url += `&${s}=${search[s]}`;
    }
  }

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
  gblOffset = gblTotal;

  // Load the first set of jobs
  org_load_chunk(gblTotal, 100);

  // Watch for any new jobs
  addNamedInterval('job_list', org_watch_job_list, 3000);
}

function org_clear_job_list() {
  // Close any open job views
  $('.collapse.in').collapse('hide');

  // Remove any timers
  clearAllNamedIntervals();

  // Clear the active jobs list
  window.active_jobs = [];

  // Hide the "Load more" button if it's visible
  $('#org-load-more').addClass('hidden');

  // Clear the job list
  $('#job-accordian tbody').empty();

  // Reset job counts
  gblTotal = 0;
  gblOffset = 0;

  // Reset the "x of y loaded" counter
  org_update_counter(gblTotal, gblOffset);
}

function org_search_form_get() {
  var name = $('#search_name').val();
  var from = $('#search_from').val();
  var to = $('#search_to').val();
  var status = $('#search_status').val();

  console.log(`name=${name} from=${from} to=${to} status=${status}`);

  var search = {};
  if( name != '' )
    search['s_name'] = name;
  if( from != '' )
    search['s_from'] = new Date(from).toISOString();
  if( to != '' )
    search['s_to'] = new Date(to).toISOString();
  if( status != 'Any' )
    search['s_status'] = status;

  return search;
}

function org_search_submit() {
  var search = org_search_form_get();
  console.log(`search=${search}`);

  if( ! $.isEmptyObject(search) ){
    // Remember the search terms that are being used
    window.search = search;

    // Reset the job list
    org_clear_job_list();

    // Find the number of jobs & load the initial set
    var url = `${gblOrganizationURL}/jobs?stats_only=true`;

    for( var s in search ){
      url += `&${s}=${search[s]}`;
    }
    console.log(`search url=${url}`);

    // Load the intial set of jobs
    api_get(url, gblUsername, org_initialize_job_list, org_job_list_failed);
  }
}

function org_search_form_reset() {
  var search = window.search;
  console.log(`search=${search}`);

  // Don't do anything if the form is already clear
  if( ! $.isEmptyObject(search) ){
    $('#search_name').val('');
    $('#search_from').val('');
    $('#search_to').val('');
    $('#search_status').val('Any');

    $('#search_btn_clear').prop('disabled', true);
    $('#search_btn_search').prop('disabled', true);

    // Clear any saved search terms
    window.search = {};

    // Reset the job list
    org_clear_job_list();

    // Load the jobs from the start
    var url = `${gblOrganizationURL}/jobs?stats_only=true`;
    api_get(url, gblUsername, org_initialize_job_list, org_job_list_failed);
  }
}

function org_search_form_changed() {
  var search = org_search_form_get();
  console.log(`search=${search}`);

  // Enable or disable the Search & Clear buttons
  if( $.isEmptyObject(search) ){
    console.log('disabling');
    $('#search_btn_clear').prop('disabled', true);
    $('#search_btn_search').prop('disabled', true);
  } else {
    console.log('enabling');
    $('#search_btn_clear').prop('disabled', false);
    $('#search_btn_search').prop('disabled', false);
  }
}
