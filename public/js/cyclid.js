// Create an interval and store the handle with a key
function addNamedInterval(name, func, interval) {
  if( window.timers == undefined ){
    console.log('initializing window.timers');
    window.timers = {};
  }

  if( window.timers[name] == null ) {
    var interval = setInterval(func, interval);
    console.log(`setting interval ${interval} as ${name}`);
    window.timers[name] = interval;
  }
}

// Remove a named interval previously created with addNamedInterval
function removeNamedInterval(name) {
  var interval = window.timers[name];

  if( interval != undefined ) {
    console.log(`clearing interval ${interval} for ${name}`);
    clearInterval(interval);
  }
  window.timers[name] = null;
}

// Remove all named intervals previously created with addNamedInterval
function clearAllNamedIntervals() {
  for(var timer in window.timers){
    console.log(`removing ${timer}`);
    removeNamedInterval(timer);
  }
}
