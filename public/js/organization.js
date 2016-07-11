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
  setTimeout(function() { ji_watch_job(url); }, 3000);
}

function org_hide_job() {
  var job_id = $(this).data('job_id');
  $('#job-info-panel').remove();

  console.log(`de-activating #row${job_id}`);
  // Remove the parent row active highlight
  $(`#row${job_id}`).removeClass('active');
}

function org_add_job(id, name, version, started, ended, status) {
  var accordian = $('#job-accordian tbody');

  var template = $('#job-info').html();
  Mustache.parse(template);

  var date_started = new Date(started).toUTCString();
  var date_ended = new Date(ended);

  if( date_ended > 0 ){
    date_ended = date_ended.toUTCString();
  } else {
    date_ended = '';
  }

  var data = {id: id,
              name: name,
              started: date_started,
              ended: date_ended,
              status: ji_job_status_to_indicator(status)};

  var new_job = Mustache.render(template, data);
  accordian.append(new_job);

  // Add the job ID to the collapsable element so it can associate itself
  // to the correct job
  $(`#collapse${id}`).data('job_id', id);
}

function org_job_list_failed(xhr) {
  var failure_message = `Failed to retrieve job list<br>
                         <strong>${xhr.status}:</strong> ${xhr.responseText}`;

  failure_message = `List failed: ${xhr.status}`;
  $('#organization_failure').html(failure_message);

  $('#organization_failure').removeClass('hidden');
}

function org_update_job_list(jobs) {
  console.log(jobs);

  // Clear the old list
  var accordian = $('#job-accordian tbody');
  accordian.empty();

  // Load the new list
  var records = jobs.records;
  var length = records.length;
  for( var i = length - 1; i >= 0; i-- ){
    var job = records[i];
    console.log(`job ${i}: ${JSON.stringify(job)}`);

    org_add_job(job.id, job.job_name, job.job_version, job.started, job.ended, job.status);
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
}

function org_load_job_list(num) {
  var pagination = $('#pagination');
  var pages,
      remainder,
      offset,
      limit;
  var url;

  pages = pagination.data('pages');
  remainder = pagination.data('remainder');

  if(num == pages) {
    limit = remainder;
    offset = 0;
  } else {
    limit = 100;
    offset = remainder + ((num - 1) * 100);
  }

  console.log(`pages=${pages} remainder=${remainder} num=${num} offset=${offset} limit=${limit}`);

  gblCurrentPage = num;

  url = `${gblOrganizationURL}/jobs?limit=${limit}&offset=${offset}`;
  api_get(url, gblUsername, org_update_job_list, org_job_list_failed);
}

function org_update_pagination(jobs) {
  console.log(jobs);

  // Calculate number of pages of jobs
  var pages = jobs.total / 100;
      remainder = pages % 1;
  pages -= remainder;
  remainder *= 100;

  if( remainder > 0 )
    pages += 1;

  console.log(`there will be ${pages} pages with a maximum of 100 jobs each. The last page will have ${remainder} jobs`)

  // Create the pagination control
  var pagination = $('#pagination');

  pagination.empty();
  pagination.bootpag({
    maxVisible: 5,
    total: pages,
    page: 1
  }).on('page', function(event, num){
    console.log(`page ${num}`);
    org_load_job_list(num);
  });

  // Store the information
  pagination.data('pages', pages);
  pagination.data('remainder', remainder);

  // Show the first page
  org_load_job_list(1);
}
