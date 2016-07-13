// Create an interval and store the handle with a key
function addNamedInterval(name, func, interval) {
  var interval = setInterval(func, interval);

  if( window.timers == undefined ){
    console.log('initializing window.timers');
    window.timers = {};
  }
  console.log(`setting interval ${interval} as ${name}`);
  window.timers[name] = interval;
}

// Remove a named interval previously created with addNamedInterval
function removeNamedInterval(name) {
  var interval = window.timers[name];

  if( interval != undefined ) {
    console.log(`clearing interval ${interval} for ${name}`);
    clearInterval(interval);
  }
  window.timers[name] = undefined;
}
