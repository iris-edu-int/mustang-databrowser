/*
 * Mazama_databrowser.js
 *
 * Jonathan Callahan
 * http://mazamascience.com
 *
 */


/**** GLOBAL VARIABLES ********************************************************/

// TODO:  These lists of metrics might be moved to a separate file to be loaded by the html page. 

// G_multiMetrics just has options
var G_multiMetrics = {
  'basic_stats':'min-max-mean',
  'latency':'latency',
  'gaps_and_overlaps':'gaps and overlaps',
  'SOH_flags':'state-of-health flag counts',
  'transfer_function':'transfer function'
};

// G_singleMetrics has both optgroups and options
var G_singleMetrics = {
  'simple metrics (daily)': {
    'dc_offset': 'dc_offset: indicator of likelihood of DC offset shift',
    'max_gap': 'max_gap: maximum gap duration',
    'max_overlap': 'max_overlap: maximum overlap duration',
    'max_stalta': 'max_stalta: maximum STA/LTA amplitude ratio',
    'num_gaps': 'num_gaps: number of gaps',
    'num_overlaps': 'num_overlaps: number of overlaps',
    'num_spikes': 'num_spikes: number of spikes detected',
    'percent_availability': 'percent_availability: percentage data available',
    'sample_min': 'sample_min: minimum amplitude',
    'sample_max': 'sample_max: maximum amplitude',
    'sample_mean': 'sample_mean: mean amplitude',
    'sample_median': 'sample_median: median amplitude',
    'sample_rms': 'sample_rms: root-mean-square variance of amplitudes',
    'sample_unique': 'sample_unique: count of unique sample values'
  },
  'latency metrics': {
    'data_latency': 'data_latency: time between data acquisition and receipt',
    // 'data_latency': 'data_latency: time between latest data acquisition and receipt',
    'feed_latency': 'feed_latency: time since latest data was received',
    'total_latency': 'total_latency: total data latency'
  },
  'PSD metrics (daily)': {
    'dead_channel_exp': 'dead_channel_exp: residuals of exp fit to PSD mean',
    // 'dead_channel_exp': 'dead_channel_exp: residuals of exponential fit to PSD mean',
    'dead_channel_gsn': 'dead_channel_gsn: TRUE/FALSE',
    'dead_channel_lin': 'dead_channel_lin: residuals of linear fit to PSD mean',
    'pct_above_nhnm': 'pct_above_nhnm: percent of PDF above New High Noise Model',
    'pct_below_nlnm': 'pct_below_nlnm: percent of PDF below New Low Noise Model'
    // 'pct_above_nhnm': 'pct_above_nhnm: percent of PDF matrix above New High Noise Model',
    // 'pct_below_nlnm': 'pct_below_nlnm: percent of PDF matrix below New Low Noise Model'
  },
  'event based metrics': {
    'cross_talk': 'cross_talk: channel cross-correlation',
    'polarity_check': 'polarity_check: near neighbor station cross-correlation',
    'sample_snr': 'sample_snr: P-wave signal-to-noise ratio'
  },
  'transfer function metrics': {
    'ms_coherence': 'ms_coherence: coherence',
    'gain_ratio': 'grain_ratio: gain ratio',
    'phase_diff': 'phase_diff: phase difference'
  },
  'miniSEED state-of-health metrics (daily flag count)': {
    'amplifier_saturation': 'amplifier_saturation: saturation detected',
    // 'amplifier_saturation': 'amplifier_saturation: amplifier saturation detected',
    'calibration_signal': 'calibration_signal: calibration signals present',
    'clock_locked': 'clock_locked: clock locked',
    'digital_filter_charging': 'digital_filter_charging: filter may be charging',
    // 'digital_filter_charging': 'digital_filter_charging: digital filter may be charging',
    'digitizer_clipping': 'digitizer_clipping: digitizer clipping detected',
    'event_begin': 'event_begin: beginning of an event, station trigger',
    'event_end': 'event_end: end of an event, station detrigger',
    'glitches': 'glitches: glitches detected',
    'missing_padded_data': 'missing_padded_data: missing/padded data present',
    'spikes': 'spikes: spikes detected',
    'suspect_time_tag': 'suspect_time_tag: time tag is questionable',
    // 'telemetry_sync_error': 'telemetry_sync_error: telemetry synchronization error',
    'telemetry_sync_error': 'telemetry_sync_error: telemetry sync error',
    'timing_correction': 'timing_correction: time correction applied'
  },
  'miniSEED state-of- health metrics (other)': {
    'timing_quality': 'timing_quality: average timing quality'
  }
};

// NOTE:  Because we are using web services in an asynchronous manner, it is helpful to use
// NOTE:  state variables so that appropriate action can be taken after the asynchronous ajax
// NOTE:  calls return.
// NOTE: 
// NOTE:  https://api.jquery.com/jquery.get/


// NOTE:  Configurable list of channels curently in the MUSTANG database
var G_mustangChannels = "CH?,DH?,LH?,MH?,SH?,EH?,EL?,BN?,HN?,LN?,BY?,DP?,BH?,HH?,BX?,HX?,VM?";

// SNCL selector arrays 
var G_virtualNetworks = [];
// var G_networks = DEFAULT_networks;                // DEFAULT_networks is defined in networks.js
// var G_stations = DEFAULT_stations;                // DEFAULT_stations is defined in stations.js
// var G_locations = DEFAULT_locations;              // DEFAULT_locations is defined in locations.js
// var G_channels = DEFAULT_channels;                // DEFAULT_channels is defined in channels.js
var G_networks = [];
var G_stations = [];
var G_locations = [];
var G_channels = [];

// SNCL selector current choice
var G_virtualNetwork = G_previous_virtualNetwork = "No virtual network";
var G_network = "IU";
var G_station = "ANMO";
var G_location = "00";
var G_channel = "BHZ";

// metric selector current choice
var G_singleMetric = 'sample_rms';
var G_multiMetric = 'basic_stats';

// response profiling information
var G_loadSecs;
var G_plotSecs;
var G_RSecs;

// state flags
var G_autoPlot = true;
var G_previousPlotRequest = false;
var G_nextPlotRequest = false;

/**** UTILITY FUNCTIONS *******************************************************/


// Display text as an error message
function displayError(errorText) {

  errorText = errorText.trim();

  if (errorText.length > 80) {
    alert(errorText);
  } else {
    // Clean up error messages
    i = errorText.lastIndexOf("Error :")
    if (i >= 0 ) { errorText = errorText.substr(i+8) }
    i = errorText.lastIndexOf("Error:")
    if (i >= 0) { errorText = errorText.substr(i+7) }

    // Display them in the requestMessage area with the default 'alert' styling.
    $('#requestMessage').addClass('alert').text(errorText);
  }
}

// Save the chosen metric
function selectMetric() {
  // Multi-metric or Single-metric
  if ( $('#plotType').val() == 'stackedMetricTimeseries' ) {
    G_multiMetric = $('#metric').val();
  } else {
    G_singleMetric = $('#metric').val();
  }
  // Handle boxplot-transfer function options
  if ( $('#plotType').val() == 'networkBoxplot' || $('#plotType').val() == 'stationBoxplot' ) {
    if ( G_singleMetric == 'ms_coherence' || G_singleMetric == 'gain_ratio' || G_singleMetric == 'phase_diff' ) {
      $('#transferFunctionCoherenceThreshold').removeClass('doNotSerialize').show();
      $('#transferFunctionOptions').show();
    } else {
      $('#transferFunctionCoherenceThreshold').addClass('doNotSerialize').hide();
      $('#transferFunctionOptions').hide();
    }
  }
}


/**** plotType SPECIFIC BEHAVIOR **********************************************/

// Adjust UI based on plotType
function selectPlotType() {

  var plotType = $('#plotType').val();

  if (plotType == 'metricTimeseries') {

    // Metric
    generateSingleMetricsSelector();
    $('#metric').removeClass('doNotSerialize').show();
    
    // Plot Buttons
    $('#previousPlot').prop('title','use previous station').prop('disabled',false);
    $('#nextPlot').prop('title','use next station').prop('disabled',false);

    // Plot Options
    $('#plotOptionsLabel').text('Plot Options for Metric Timeseries');
    $('#boxplotShowOutliers').addClass('doNotSerialize').hide();
    $('#boxplotOptions').hide();
    $('#transferFunctionCoherenceThreshold').addClass('doNotSerialize').hide();
    $('#transferFunctionOptions').hide();
    $('#timeseriesChannelSet').removeClass('doNotSerialize').show();
    $('#timeseriesOptions').show();

    // SNCL
    $('#network').removeClass('doNotSerialize');
    $('#station').removeClass('doNotSerialize');
    $('#location').removeClass('doNotSerialize').show();
    $('#channel').removeClass('doNotSerialize').show();
    // $( "#location-auto").show();
    // $( "#channel-auto").show();

  } else if (plotType == 'stackedMetricTimeseries') {

    // Metric
    generateMultiMetricsSelector();
    $('#metric').removeClass('doNotSerialize').show();

    // Plot Buttons
    $('#previousPlot').prop('title','use previous station').prop('disabled',false);
    $('#nextPlot').prop('title','use next station').prop('disabled',false);

    // Plot Options
    $('#plotOptionsLabel').text('No Plot Options for Multi-Metric Timeseries');
    $('#boxplotShowOutliers').addClass('doNotSerialize').hide();
    $('#boxplotOptions').hide();
    $('#transferFunctionCoherenceThreshold').addClass('doNotSerialize').hide();
    $('#transferFunctionOptions').hide();
    $('#timeseriesChannelSet').addClass('doNotSerialize').hide();
    $('#timeseriesOptions').hide();

    // SNCL
    $('#network').removeClass('doNotSerialize');
    $('#station').removeClass('doNotSerialize');
    $('#location').removeClass('doNotSerialize').show();
    $('#channel').removeClass('doNotSerialize').show();
    // $( "#location-auto").show();
    // $( "#channel-auto").show();

  } else if (plotType == 'networkBoxplot') {

    // Metric
    generateSingleMetricsSelector();
    $('#metric').removeClass('doNotSerialize').show();

    // Plot Buttons
    if ( G_virtualNetwork == 'No virtual network' ) {
      $('#previousPlot').prop('title','use previous network').prop('disabled',false);
      $('#nextPlot').prop('title','use next network').prop('disabled',false);      
    } else {
      // Disable prev/next for virtual networks which act as a single network
      $('#previousPlot').prop('disabled',true);
      $('#nextPlot').prop('disabled',true);
    }

    // Plot Options
    $('#timeseriesChannelSet').addClass('doNotSerialize').hide();
    $('#timeseriesOptions').hide();
    $('#plotOptionsLabel').text('Plot Options for Boxplots');
    $('#boxplotShowOutliers').removeClass('doNotSerialize').show();
    $('#boxplotOptions').show();
    var metricName = $('#metric').val();
    if (metricName == 'ms_coherence' || metricName == 'gain_ratio' || metricName == 'phase_diff') {
      $('#transferFunctionCoherenceThreshold').removeClass('doNotSerialize').show();
      $('#transferFunctionOptions').show();
    } else {
      $('#transferFunctionCoherenceThreshold').addClass('doNotSerialize').hide();
      $('#transferFunctionOptions').hide();
    }

    // SNCL
    // NOTE:  Leave station in place to provide full access to alll possible loc-cha
    // NOTE:  but prevent the choice of station from skipping over a cache hit.
    if ( G_virtualNetwork == 'No virtual network' ) {
      $('#network').removeClass('doNotSerialize');
    } else {
      $('#network').addClass('doNotSerialize');
    }
    $('#station').addClass('doNotSerialize');
    $('#location').removeClass('doNotSerialize').show();
    $('#channel').removeClass('doNotSerialize').show();
    // $( "#location-auto").show();
    // $( "#channel-auto").show();

  } else if (plotType == 'stationBoxplot') {

    // Metric
    generateSingleMetricsSelector();
    $('#metric').removeClass('doNotSerialize').show();

    // Plot Buttons
    $('#previousPlot').prop('title','use previous station').prop('disabled',false);
    $('#nextPlot').prop('title','use next station').prop('disabled',false);

    // Plot Options
    $('#timeseriesChannelSet').addClass('doNotSerialize').hide();
    $('#timeseriesOptions').hide();
    $('#plotOptionsLabel').text('Plot Options for Boxplots');
    $('#boxplotShowOutliers').removeClass('doNotSerialize').show();
    $('#boxplotOptions').show();
    var metricName = $('#metric').val();
    if (metricName == 'ms_coherence' || metricName == 'gain_ratio' || metricName == 'phase_diff') {
      $('#transferFunctionCoherenceThreshold').removeClass('doNotSerialize').show();
      $('#transferFunctionOptions').show();
    } else {
      $('#transferFunctionCoherenceThreshold').addClass('doNotSerialize').hide();
      $('#transferFunctionOptions').hide();
    }

    // SNCL
    $('#network').removeClass('doNotSerialize');
    $('#station').removeClass('doNotSerialize');
    $('#location').addClass('doNotSerialize').hide();
    $('#channel').addClass('doNotSerialize').hide();
    // $( "#location-auto").hide();
    // $( "#channel-auto").hide();

  } else if (plotType == 'trace' ||
             plotType == 'pdf') {

    // Metric
    $('#metric').addClass('doNotSerialize').hide();

    // Plot Buttons
    $('#previousPlot').prop('title','use previous station').prop('disabled',false);
    $('#nextPlot').prop('title','use next station').prop('disabled',false);

    // Plot Options
    if (plotType == 'trace') {
      $('#plotOptionsLabel').text('No Plot Options for Trace plots');
    } else {
      $('#plotOptionsLabel').text('No Plot Options for PDF plots');
    }
    $('#boxplotShowOutliers').addClass('doNotSerialize').hide();
    $('#boxplotOptions').hide();
    $('#transferFunctionCoherenceThreshold').addClass('doNotSerialize').hide();
    $('#transferFunctionOptions').hide();
    $('#timeseriesChannelSet').addClass('doNotSerialize').hide();
    $('#timeseriesOptions').hide();
    
    // SNCL
    $('#network').removeClass('doNotSerialize');
    $('#station').removeClass('doNotSerialize');
    $('#location').removeClass('doNotSerialize').show();
    $('#channel').removeClass('doNotSerialize').show();
    // $( "#location-auto").show();
    // $( "#channel-auto").show();

  } 

  // We usually want to generate a plot
  if (G_autoPlot) sendPlotRequest();

}


/**** METRICS SELECTORS *******************************************************/

function generateSingleMetricsSelector(){
  var sel = $('#metric');
  sel.empty();

  // G_singleMetrics includes optgroups in the hierarchy
  for (optgroup in G_singleMetrics) {
    sel.append('<optgroup label="' + optgroup + '">');
    var optionDict = G_singleMetrics[optgroup];
    for (option in optionDict) {
      if (option == G_singleMetric) { // Retain previously chosen metric
        sel.append('<option selected="selected" value="' + option + '">' + optionDict[option] + '</option>');
      } else {
        sel.append('<option value="' + option + '">' + optionDict[option] + '</option>');
      }
    }
    sel.append('</optgroup>');
  }
}


function generateMultiMetricsSelector(){
  var sel = $('#metric');
  sel.empty();

  // G_singleMetrics does not include optgroups in the hierarchy
  optionDict = G_multiMetrics
  for (option in optionDict) {
    if (option == G_multiMetric) { // Retain previously chosen metric
      sel.append('<option selected="selected" value="' + option + '">' + optionDict[option] + '</option>');
    } else {
      sel.append('<option value="' + option + '">' + optionDict[option] + '</option>');
    }
  }
}


/**** CASCADING SNCL SELECTORS ************************************************/

// Generate Virtual Network selector -------------------------------------------
// NOTE:  Should only be called once during startup

function generateVirtualNetworksSelector(){
  // Get the list of options
  var options = G_virtualNetworks;

  // If the current virtual network is not in the list of virtual networks, choose the first available
  if (options.indexOf(G_virtualNetwork) < 0) {
    G_virtualNetwork = options[0];
  }

  // Empty the selector
  var sel = $('#virtualNetwork');
  sel.empty();

  // Repopulate the selector
  for (var i=0; i<options.length; i++) {
    if (options[i] == G_virtualNetwork) {
      sel.append('<option selected="selected" value="' + options[i] + '">' + options[i] + '</option>');
    } else {
      sel.append('<option value="' + options[i] + '">' + options[i] + '</option>');
    }
  }

}


// Generate Network selector ---------------------------------------------------

function generateNetworksSelector() {
  // Get the list of options
  var options = G_networks

  // If the current network is not in the list of networks, choose the first available
  if (options.indexOf(G_network) < 0) {
    G_network = options[0];
  }

  // Empty the selector
  var sel = $('#network');
  sel.empty();

  // Repopulate the selector
  for (var i=0; i<options.length; i++) {
    if (options[i] == G_network) {
      sel.append('<option selected="selected" value="' + options[i] + '">' + options[i] + '</option>');
    } else {
      sel.append('<option value="' + options[i] + '">' + options[i] + '</option>');
    }
  }

  // Update the associated autocomplete box
  $("#network-auto").autocomplete({source: options});
  $("#network-auto").val("");
 
  ajaxUpdateSNCLSelectors(); // ends with generateStationsSelector() and then running the passed in function
}


// Generate Station selector ---------------------------------------------------

function generateStationsSelector(){
  // Get the list of options
  var options = G_stations[G_network].sort();

  // If the current station is not in the network
  if (options.indexOf(G_station) < 0) {
    if (G_previousPlotRequest) {
      G_station = options[options.length-1];
    } else {
      G_station = options[0]; // behavior for default and 'Next'
    }
  }

  // Empty the selector
  var sel = $('#station');
  sel.empty();
  
  // Repopulate the selector
  for (var i=0; i<options.length; i++) {
    if (options[i] == G_station) {
      sel.append('<option selected="selected" value="' + options[i] + '">' + options[i] + '</option>');
    } else {
      sel.append('<option value="' + options[i] + '">' + options[i] + '</option>');
    }
  }
  
  // Update the associated autocomplete box
  $("#station-auto").autocomplete({source: options});
  $("#station-auto").val("");
 
  generateLocationsSelector();
}


// Generate Locations selector -------------------------------------------------

function generateLocationsSelector(){

  var plotType = $('#plotType').val();

  // Get the list of options
  var NS = G_network + '.' + G_station;
  var options = G_locations[NS].sort();

  // If the current location is not in the station
  if (options.indexOf(G_location) < 0) {
    if (G_previousPlotRequest) {
      G_location = options[options.length-1];
    } else {
      G_location = options[0]; // behavior for default and 'Next'
    }
  }

  // Empty the selector
  var sel = $('#location');
  sel.empty();

  // Repopulate the selector
  for (var i=0; i<options.length; i++) {
    if (options[i] == G_location) {
      sel.append('<option selected="selected" value="' + options[i] + '">' + options[i] + '</option>');
    } else {
      sel.append('<option value="' + options[i] + '">' + options[i] + '</option>');
    }
  }
  
  // Update the associated autocomplete box
  $("#location-auto").autocomplete({source: options});
  $("#location-auto").val("");
 
  generateChannelsSelector();
}

// Generate Channels selector --------------------------------------------------

function generateChannelsSelector(){
  // Get the list of options
  var NSL = G_network + '.' + G_station + '.' + G_location;
  var options = G_channels[NSL].sort();
  
  // If the current channel is not in the location
  if (options.indexOf(G_channel) < 0) {
    if (G_previousPlotRequest) {
      // // //G_channel = options[options.length-1];
      previousPlot(); // asynchronous
      return;
    } else if (G_nextPlotRequest) {
      nextPlot(); // asynchronous
      return;
    } else {
      G_channel = options[0]; // behavior for default and 'Next'
    }
  }

  // Empty the selector
  var sel = $('#channel');
  sel.empty();
  
  // If this channel is not in the location, choose the first available
  if (options.indexOf(G_channel) < 0) {
    G_channel = options[0];
  }

  for (var i=0; i<options.length; i++) {
    if (options[i] == G_channel) {
      sel.append('<option selected="selected" value="' + options[i] + '">' + options[i] + '</option>');
    } else {
      sel.append('<option value="' + options[i] + '">' + options[i] + '</option>');
    }
  }

  // Update the associated autocomplete box
  $("#channel-auto").autocomplete({source: options});
  $("#channel-auto").val(""); 

  // We usually want to generate a plot after regenerating this final selector
  if (G_autoPlot) sendPlotRequest();

}

// ***** USER INITIATED SELECTIONS *******************************************/

function selectVirtualNetwork(){
  G_previousPlotRequest = false;
  G_nextPlotRequest = false;
  G_previousVirtualNetwork = G_virtualNetwork; // in case the web request in ajaxUpdateNetworks() fails
  G_virtualNetwork = $('#virtualNetwork').val();

  // Adjust UI if networkBoxplot is selected
  if ( $('#plotType').val() == 'networkBoxplot' && G_virtualNetwork != 'No virtual network' ) {
    $('#network').addClass('doNotSerialize');
    $('#previousPlot').prop('disabled',true);
    $('#nextPlot').prop('disabled',true);
  } else {
    $('#network').removeClass('doNotSerialize');
    $('#previousPlot').prop('disabled',false);
    $('#nextPlot').prop('disabled',false);
  }

  ajaxUpdateNetworks(); // ends with generateNetworksSelector()
}

function selectNetwork(){
  G_previousPlotRequest = false;
  G_nextPlotRequest = false;
  G_network = $('#network').val();
  generateNetworksSelector(sendPlotRequest);
}

function selectStation(){
  G_previousPlotRequest = false;
  G_nextPlotRequest = false;
  G_station = $('#station').val();
  generateStationsSelector();
}

function selectLocation(){
  G_previousPlotRequest = false;
  G_nextPlotRequest = false;
  G_location = $('#location').val();
  generateLocationsSelector();
}

function selectChannel(){
  G_previousPlotRequest = false;
  G_nextPlotRequest = false;
  G_channel = $('#channel').val();
  generateChannelsSelector();
}

function selectStartDate(dateText, inst) {
  G_previousPlotRequest = false;
  G_nextPlotRequest = false;
  validateDates(); // required to set starttime and endtime fields
  ajaxUpdateSNCLSelectors(); // ends with generateStationsSelector() and then running the passed in function
}

function selectEndDate(dateText, inst) {
  G_previousPlotRequest = false;
  G_nextPlotRequest = false;
  validateDates(); // required to set starttime and endtime fields
  ajaxUpdateSNCLSelectors(); // ends with generateStationsSelector() and then running the passed in function
}

// Set the global channel variable from auto-complete box ----------------------

function selectNetworkAuto(event, ui){
  G_previousPlotRequest = false;
  G_nextPlotRequest = false;
  G_network = ui.item.value;
  generateNetworksSelector();
}

function selectStationAuto(event, ui){
  G_previousPlotRequest = false;
  G_nextPlotRequest = false;
  G_station = ui.item.value;
  generateStationsSelector();
}

function selectLocationAuto(event, ui){
  G_previousPlotRequest = false;
  G_nextPlotRequest = false;
  G_location = ui.item.value;
  generateLocationsSelector();
}

function selectChannelAuto(event, ui){
  G_previousPlotRequest = false;
  G_nextPlotRequest = false;
  G_channel = ui.item.value;
  generateChannelsSelector();
}

 
/**** PREV/NEXT BUTTONS ******************************************************/

// Move to the previous available location/station that shares the current channel
function previousPlot() {

  G_previousPlotRequest = true;
  G_nextPlotRequest = false;

  $('#activityMessage').text('').removeClass('alert');

  var plotType = $('#plotType').val();

  if (plotType == 'networkBoxplot') {

    // dcrement the network
    var networkIndex = G_networks.indexOf(G_network);
    if (networkIndex == 0) {
      $('#previousPlot').prop('disabled',true);
      $('#activityMessage').text('no previous networks').addClass('alert');      
    } else {
      $('#previousPlot').prop('disabled',false);
      networkIndex--;
      G_network = G_networks[networkIndex];
      generateNetworksSelector(); // trigger the cascading selectors
    }

  } else if (plotType == 'stationBoxplot') {

    // stationBoxplots decrement the station within the network or virtualNetwork
    
    var N = G_network;

    var allStations = G_stations[N].sort();

    var networkIndex = G_networks.indexOf(G_network);
    var stationIndex = allStations.indexOf(G_station);

    // Try to decrement the station if possible
    if (stationIndex > 0) {
      stationIndex--;
      G_station = allStations[stationIndex];
      generateStationsSelector(); // trigger the cascading selectors
      return;
    }

    // If we have run out of stations, try to decrement the network
    if (networkIndex > 0) {
      networkIndex--;
      G_network = G_networks[networkIndex];
      ajaxUpdateNetworks(); // ultimate business logic is found in generateStationsSelector()
      return;
    } else {
      $('#activityMessage').text('no previous stations').addClass('alert');      
    }

  } else {

    // All other plot types decrement the location and then the station

    var currentNetwork = $('#network').val();
    var currentStation = $('#station').val();
    var currentLocation = $('#location').val();
    var currentChannel = $('#channel').val();

    var N = currentNetwork;
    var NS = currentNetwork + '.' + currentStation;
    var NSL = currentNetwork + '.' + currentStation + '.' + currentLocation;

    var allStations = G_stations[N].sort();
    var allLocations = G_locations[NS].sort();
    var allChannels = G_channels[NSL].sort();

    var networkIndex = G_networks.indexOf(G_network);
    var stationIndex = allStations.indexOf(currentStation);
    var locationIndex = allLocations.indexOf(currentLocation);

    // Try to decrement the location if possible
    while (locationIndex > 0) {

      locationIndex--;
      NSL = currentNetwork + '.' + currentStation + '.' + allLocations[locationIndex];
      allChannels = G_channels[NSL].sort();
      if (allChannels.indexOf(currentChannel) >= 0) {
        $('#nextPlot').prop('disabled',false); // successful decrement so now Next should be enabled
        G_location = allLocations[locationIndex];
        generateLocationsSelector(); // trigger the cascading selectors
        return;
      } 

    }

    // If we have run out of locations, try to decrement the station
    while (stationIndex > 0) {

      stationIndex--;
      currentStation = allStations[stationIndex];
      NS = currentNetwork + '.' + currentStation;
      allLocations = G_locations[NS].sort();
      locationIndex = allLocations.length;

      while (locationIndex > 0) {

        locationIndex--;
        NSL = currentNetwork + '.' + currentStation + '.' + allLocations[locationIndex];
        allChannels = G_channels[NSL].sort();

        if (allChannels.indexOf(currentChannel) >= 0) {
          $('#nextPlot').prop('disabled',false); // successful decrement so now Next should be enabled
          G_station = currentStation;
          G_location = allLocations[locationIndex];
          generateStationsSelector(); // trigger the cascading selectors
          return;
        }

      } // END locationIndex while loop

    } // END stationIndex while loop

    // If we have run out of stations, try to decrement the network
    if (networkIndex > 0) {
      networkIndex--;
      G_network = G_networks[networkIndex];
      ajaxUpdateNetworks(); // ultimate business logic is found in generateStationsSelector()
      return;
    } else {
      $('#activityMessage').text('no previous stations with this channel').addClass('alert');      
    }

  } // END plotType

}


// Move to the next available location/station that shares the current channel
function nextPlot() {

  G_previousPlotRequest = false;
  G_nextPlotRequest = true;

  $('#activityMessage').text('').removeClass('alert');

  var plotType = $('#plotType').val();

  if (plotType == 'networkBoxplot') {

    // networkBoxplots increment the network

    var networkIndex = G_networks.indexOf(G_network);
    if (networkIndex == G_networks.length-1) {
      $('#nextPlot').prop('disabled',true);
      $('#activityMessage').text('no more networks').addClass('alert');      
      return;
    } else {
      $('#nextPlot').prop('disabled',false);
      networkIndex++;
      G_network = G_networks[networkIndex];
      generateNetworksSelector(sendPlotRequest); // trigger the cascading selectors
      return;
    }

  } else if (plotType == 'stationBoxplot') {

    // stationBoxplots increment the station within the network or virtualNetwork

    var N = G_network;

    var allStations = G_stations[N].sort();

    var networkIndex = G_networks.indexOf(G_network);
    var stationIndex = allStations.indexOf(G_station);

    // Try to increment the station if possible
    if (stationIndex < allStations.length-1) {
      stationIndex++;
      G_station = allStations[stationIndex];
      generateStationsSelector(); // trigger the cascading selectors
      return;
    }

    // If we have run out of stations, try to increment the network
    if (networkIndex < G_networks.length-1) {
      networkIndex++;
      G_network = G_networks[networkIndex];
      ajaxUpdateNetworks(); // ultimate business logic is found in generateStationsSelector()
      return;
    } else {
      $('#activityMessage').text('no more stations').addClass('alert');      
    }


  } else {

    // All other plot types increment the location and then the station

    var currentNetwork = $('#network').val();
    var currentStation = $('#station').val();
    var currentLocation = $('#location').val();
    var currentChannel = $('#channel').val();

    var N = currentNetwork;
    var NS = currentNetwork + '.' + currentStation;
    var NSL = currentNetwork + '.' + currentStation + '.' + currentLocation;

    var allStations = G_stations[N].sort();
    var allLocations = G_locations[NS].sort();
    var allChannels = G_channels[NSL].sort();

    var networkIndex = G_networks.indexOf(G_network);
    var stationIndex = allStations.indexOf(currentStation);
    var locationIndex = allLocations.indexOf(currentLocation);

    // Try to increment the location if possible
    while (locationIndex < allLocations.length-1) {

      locationIndex++;
      NSL = currentNetwork + '.' + currentStation + '.' + allLocations[locationIndex];
      allChannels = G_channels[NSL].sort();
      if (allChannels.indexOf(currentChannel) >= 0) {
        $('#previousPlot').prop('disabled',false); // successful increment so now Previous should be enabled
        G_location = allLocations[locationIndex];
        generateLocationsSelector(); // trigger the cascading selectors
        return;
      } 

    }

    // If we have run out of locations, try to increment the station
    while (stationIndex < allStations.length-1) {

      stationIndex++;
      currentStation = allStations[stationIndex];
      NS = currentNetwork + '.' + currentStation;
      allLocations = G_locations[NS].sort();
      locationIndex = -1; // so that we start at index 0

      while (locationIndex < allLocations.length-1) {

        locationIndex++;
        NSL = currentNetwork + '.' + currentStation + '.' + allLocations[locationIndex];
        allChannels = G_channels[NSL].sort();

        if (allChannels.indexOf(currentChannel) >= 0) {
          $('#previousPlot').prop('disabled',false); // successful increment so now Previous should be enabled
          G_station = currentStation;
          G_location = allLocations[locationIndex];
          generateStationsSelector(); // trigger the cascading selectors
          return;
        } 

      } // END locationIndex while loop

    } // END stationIndex while loop

    // If we have run out of stations, try to increment the network
    if (networkIndex < G_networks.length-1) {
      networkIndex++;
      G_network = G_networks[networkIndex];
      ajaxUpdateNetworks(); // ultimate business logic is found in generateStationsSelector()
      return;
    } else {
      $('#activityMessage').text('no more stations with this channel').addClass('alert');      
    }

  } // END plotType

}


// Send request to plot current selection
function plotData() {
  G_previousPlotRequest = false;
  G_nextPlotRequest = false;
  sendPlotRequest();
}

/**** EVENT HANDLERS **********************************************************/

// Validate dates and sets starttime and endtime fields
function validateDates() {
  var startDate = $('#datepicker1').datepicker("getDate");
  var endDate = $('#datepicker2').datepicker("getDate");

  // Sanity check
  if (endDate < startDate) {
    alert("End date < start date! Resetting end date.");
    endDate = new Date(startDate);
    endDate.setDate(endDate.getDate() + 1);
    $('#datepicker2').datepicker("setDate",endDate);
  }

  var starttimeString = $.datepicker.formatDate('yy-mm-dd',startDate);
  var endtimeString = $.datepicker.formatDate('yy-mm-dd',endDate);
  $('#starttime').val(starttimeString);
  $('#endtime').val(endtimeString);
}


/**** CGI REQUEST HANDLER *****************************************************/

// Serialize the form and send it to the CGI.
// Note that some UI elements have no bearing on the product generated and
// should be removed from the request to improve our cache hit rate.
function sendPlotRequest() {
  validateDates(); // required to set starttime and endtime fields
  var url = '/cgi-bin/__DATABROWSER__.cgi';
  var paramsUrl = $('#controls_form').serialize();
  var removeList = $('.doNotSerialize');
  for (i=0; i<removeList.length; i++) {
     var valueString = $(removeList[i]).serialize();
     if (valueString != '') {
       var removeString = '&' + valueString;
       paramsUrl = paramsUrl.replace(removeString,'');
     }
  }
  // Special handling for timseriesChannelSet option -- 10/31/2016
  // Make the last character a question mark.
  if ($('#timeseriesChannelSet').prop('checked') &&
      !$('#timeseriesChannelSet').hasClass('doNotSerialize')) {
    var channelString = "channel=" + $('#channel').val();
    var chasetString = "channel=" + $('#channel').val().substr(0,2) + "?";
    paramsUrl = paramsUrl.replace(channelString,chasetString);
  }
  // UI changes
  $('#spinner').fadeIn(1000);
  $('#profiling_container').hide();
  $('#dataLink_container').hide();
  $('#requestMessage').text('').removeClass('alert');
  $('#activityMessage').text('plot request').addClass('info');
  // Debugging output
  console.log(url + "?" + paramsUrl);

  // Make the request
  $.getJSON(url, paramsUrl).done(function(JSONResponse) {
    if (JSONResponse.status == 'ERROR') {
      $('#plot').css({ opacity: 0.5 });
      displayError(JSONResponse.error_text);
    } else {
      $('#plot').css({ opacity: 1.0 });
      // NOTE:  If more than one result is generated, they should have names
      // NOTE:  derived from the basename.
      var img_url = JSONResponse.rel_base + ".png";
      //var img_url = "/mustang/databrowser/" + JSONResponse.rel_base + ".png";
      $('#plot').attr('src',img_url);
      // The returnObject is a JSON serialization of an R list.
      var returnObject = $.parseJSON(JSONResponse.return_json); 
      var dummy = 1;

      G_loadSecs = returnObject.loadSecs;
      G_plotSecs = returnObject.plotSecs;
      G_RSecs = returnObject.totalSecs;

      $('#loadSecs').text(G_loadSecs.toFixed(2));
      $('#plotSecs').text(G_plotSecs.toFixed(2));
      $('#RSecs').text(G_RSecs.toFixed(2));

      // format the MUSTANG URL we will display for the user
      // if this is a measurements url, append orderby=start
      displayURL = returnObject.bssUrl
      if (displayURL.indexOf("measurements") > -1) {
      	displayURL = returnObject.bssUrl + "&orderby=start"
      }
      $('#bssDataLink').attr('href',displayURL);
    }
  }).fail(function(jqXHR, textStatus, errorThrown) {
    alert("CGI error: " + textStatus);
  }).always(function() {
    G_previousPlotRequest = false;
    G_nextPlotRequest = true;
    // UI changes
    $('#spinner').hide();
    $('#profiling_container').show();
    $('#dataLink_container').show();
    $('#activityMessage').text('').removeClass('info').removeClass('alert');
  });
}


/**** IRIS WEBSERVICE HANDLERS ************************************************/

// Get a list of virtual network codes and repopulate the virtual networks selector
function ajaxUpdateVirtualNetworksSelector() {
  var url = 'http://service.iris.edu/irisws/virtualnetwork/1/codes'; // response is always XML
  $.get(url).done(function(serviceResponse) {
    // NOTE:  This function is a 'promise' that gets evaluated asynchronously
    var vnetNodes = serviceResponse.getElementsByTagName("virtualNetwork");
    var vnetCodes = $.map(vnetNodes, function(elem, i) { return(elem.getAttribute("code")); } );
    // var vnetDescriptions = $.map(vnetNodes, function(elem, i) { return(elem.firstElementChild.textContent); } );
    G_virtualNetworks = vnetCodes.sort();
    G_virtualNetworks.splice(0,0,"No virtual network");
    generateVirtualNetworksSelector(); // based on the values in G_virtualNetworks
    // Now update the networks selector
    ajaxUpdateNetworks();
  }).fail(function(jqXHR, textStatus, errorThrown) {
    alert("Error updating virtual networks: " + textStatus);
  }).always(function() {
    var a=1;
  });
}

/* ------------------------------------------------------------------------- */
// Web services request for level=network metadata with a promise to generateNetworksSelector()
// This happens whenever a new virtual network is selected
function ajaxUpdateNetworks() {

  // UI cues
  $('#profiling_container').hide();
  $('#dataLink_container').hide();
  $('#activityMessage').text('rebuilding Network selectors').addClass('info');

  var network = G_virtualNetwork;
  if (G_virtualNetwork == "No virtual network") {
    network = "*";
  }

  var url = 'http://service.iris.edu/fdsnws/station/1/query';
  var data = {net:network,
              sta:"*",
              loc:"*",
              cha:G_mustangChannels,
              starttime:$('#starttime').val(),
              endtime:$('#endtime').val(),
              level:"network",
              nodata:"404",
              format:"text"};
  console.log(url + "?" + $.param(data));
  $.get(url, data).done(function(serviceResponse) {

    $('#activityMessage').text("rebuilding Network selectors");

    // Read in the response with PapaParse
    var config = {
      delimiter: "",  // auto-detect
      newline: "",  // auto-detect
      quoteChar: '"',
      header: false, // NOTE:  When 'true', each row becomes an associative array and it all gets more complicated
      dynamicTyping: false,
      preview: 0,
      encoding: "",
      worker: false,
      comments: false,
      step: undefined,
      complete: undefined,
      error: undefined,
      download: false,
      skipEmptyLines: true, // false,
      chunk: undefined,
      fastMode: undefined,
      beforeFirstChunk: undefined,
      withCredentials: undefined
    }
    var result = Papa.parse(serviceResponse, config);
    // TODO:  Could handler errors or parsing issues here

    // Response is a '|' separated file with a hedaer like this:
    // #Network | Description | StartTime | EndTime | TotalStations

    // Separate header from data
    var header = result.data.slice(0,1);
    var data = result.data.slice(1);

    // NOTE:  By having the timerange in the request, all returned data should be valid

    // Extract columns of data
    var Ns = $.map(data, function(row, i) { return(row[0]); } );
    // Create unique arrays
    var uniqueNs = Ns.filter(function(val, i) { return(Ns.indexOf(val)==i); }).sort();

    // Replace the G_networks array
    G_networks = uniqueNs;

    // Trigger the cascading selectors
    generateNetworksSelector();

  }).fail(function(jqXHR, textStatus, errorThrown) {

    if (jqXHR.status == 404) {
      alert("No station metadata found for the selected virtual network and time range.");
    }
    // Restore previous virtual network selection
    G_virtualNetwork = G_previousVirtualNetwork;
    generateVirtualNetworksSelector();   

  }).always(function() {

    $('#requestMessage').text('').removeClass('alert');
    $('#activityMessage').text('').removeClass('info').removeClass('alert');
    // $('#profiling_container').show();
    // $('#dataLink_container').show();

  });

}

/* ------------------------------------------------------------------------- */
// Query for level=channel metadata for the current network and repopulate all SNCL selectors
function ajaxUpdateSNCLSelectors() {

  // UI cues
  $('#profiling_container').hide();
  $('#dataLink_container').hide();
  $('#activityMessage').text('rebuilding SNCL selectors').addClass('info');

  var network = G_virtualNetwork;
  if (G_virtualNetwork == "No virtual network") {
    network = G_network;
  }

  var url = 'http://service.iris.edu/fdsnws/station/1/query';
  var data = {net:network,
              sta:"*",
              loc:"*",
              cha:G_mustangChannels,
              starttime:$('#starttime').val(),
              endtime:$('#endtime').val(),
              level:"channel",
              nodata:"404",
              format:"text"};
  console.log(url + "?" + $.param(data));
  $.get(url, data).done(function(serviceResponse) {

    $('#activityMessage').text("rebuilding SNCL selectors");

    // Read in the response with PapaParse
    var config = {
      delimiter: "",  // auto-detect
      newline: "",  // auto-detect
      quoteChar: '"',
      header: false, // NOTE:  When 'true', each row becomes an associative array and it all gets more complicated
      dynamicTyping: false,
      preview: 0,
      encoding: "",
      worker: false,
      comments: false,
      step: undefined,
      complete: undefined,
      error: undefined,
      download: false,
      skipEmptyLines: true, // false,
      chunk: undefined,
      fastMode: undefined,
      beforeFirstChunk: undefined,
      withCredentials: undefined
    }
    var result = Papa.parse(serviceResponse, config);
    // TODO:  Could handler errors or parsing issues here

    // Response is a '|' separated file with a hedaer like this:
    // #Network | Station | Location | Channel | Latitude | Longitude | Elevation | Depth | Azimuth | Dip | SensorDescription | Scale | ScaleFreq | ScaleUnits | SampleRate | StartTime | EndTime

    // Separate header from data
    var header = result.data.slice(0,1);
    var data = result.data.slice(1);

    // NOTE:  By having the timerange in the request, all returned data should be valid

    // Convert returned locations of "" into "--"
    $.each(data, function(i, row) {
      if ( row[2] == "" ) data[i][2] = "--";
    });

    // Extract columns of data
    var NSs = $.map(data, function(row, i) { return(row[0] + '.' + row[1]); } );
    var NSLs = $.map(data, function(row, i) { return(row[0] + '.' + row[1] + '.' + row[2]); } );
    var NSLCs = $.map(data, function(row, i) { return(row[0] + '.' + row[1] + '.' + row[2] + '.' + row[3]); } );

    // Create unique arrays
    var uniqueNSs = NSs.filter(function(val, i) { return(NSs.indexOf(val)==i); }).sort();
    var uniqueNSLs = NSLs.filter(function(val, i) { return(NSLs.indexOf(val)==i); }).sort();
    var uniqueNSLCs = NSLCs.filter(function(val, i) { return(NSLCs.indexOf(val)==i); }).sort();

    // Replace the G_stations "station by network" associative array
    G_stations = {};
    $.each(G_networks, function(i, N) {
      // Find NSs that start with 'net'
      // Then create a unique, sorted list of these NSs
      // Add an array of the 'sta' part to G_stations with 'net' as the key
      var N_NSs = NSs.filter( function(val) { return(val.startsWith(N)); } );
      var N_uniqueNSs = N_NSs.filter(function(val, i) { return(N_NSs.indexOf(val)==i); }).sort();
      G_stations[N] = $.map(N_uniqueNSs, function(elem, i) { return(elem.split('.')[1]); } );
    })

    // Replace the G_locations "location by net.sta" associative array
    G_locations = {};
    $.each(uniqueNSs, function(i, NS) {
      // Find NSLs that start with 'net.sta'
      // Then create a unique, sorted list of these NSLs
      // Add an array of the 'loc' part to G_locations with 'net.sta' as the key
      var NS_NSLs = NSLs.filter( function(val) { return(val.startsWith(NS)); } );
      var NS_uniqueNSLs = NS_NSLs.filter(function(val, i) { return(NS_NSLs.indexOf(val)==i); }).sort();
      G_locations[NS] = $.map(NS_uniqueNSLs, function(elem, i) { return(elem.split('.')[2]); } );
    })
    
    // Replace the G_channels "channel by net.sta.loc" associative array
    G_channels = {};
    $.each(uniqueNSLs, function(i, NSL) {
      // Find NSLCs that start with 'net.sta.loc'
      // Then create a unique, sorted list of these NSLCs
      // Add an array of the 'cha' part to G_chananels with 'net.sta.loc' as the key
      var NSL_NSLCs = NSLCs.filter( function(val) { return(val.startsWith(NSL)); } );
      var NSL_uniqueNSLCs = NSL_NSLCs.filter(function(val, i) { return(NSL_NSLCs.indexOf(val)==i); }).sort();
      G_channels[NSL] = $.map(NSL_uniqueNSLCs, function(elem, i) { return(elem.split('.')[3]); } );
    })
    
    // Regenerate all selectors based on the new G_~ arrays
    generateStationsSelector();

    // $(document).triggerHandler('finishedUpdatingSNCLSelectors');

  }).fail(function(jqXHR, textStatus, errorThrown) {

    if (jqXHR.status == 404) {
      // Service returned "no data found" -- possibly due to an inappropriate time range
      alert('No station metadata found for the selected virtual network and time range.');
    }

  }).always(function() {

    $('#requestMessage').text('').removeClass('alert');
    $('#activityMessage').text('').removeClass('info').removeClass('alert');
    // $('#profiling_container').show();
    // $('#dataLink_container').show();

  });

}

/**** EXPERIMENT WITH TRIGGERS ************************************************/

// $(document).on('finishedUpdatingSNCLSelectors', function(e, arg1, arg2, arg3) {
//   console.log("immediately after updating the SNCL selectors");
// });


/**** INITIALIZATION **********************************************************/

$(function() {
  // Hide things that shouldn't appear at first
  $('#spinner').hide();
  $('#boxplotShowOutliers').addClass('doNotSerialize').hide();
  $('#boxplotOptions').hide();
  $('#transferFunctionCoherenceThreshold').addClass('doNotSerialize').hide();
  $('#transferFunctionOptions').hide();
  $('#profiling_container').hide();

  // Metric selector
  generateSingleMetricsSelector();
  
  // Cascading SNCL selectors
  $('#virtualNetwork').change(selectVirtualNetwork);
  $('#network').change(selectNetwork);
  $('#station').change(selectStation);
  $('#location').change(selectLocation);
  $('#channel').change(selectChannel);

  // Assoociated SNCL autocompletes
  $( "#network-auto").on( "autocompleteselect", selectNetworkAuto );
  $( "#station-auto").on( "autocompleteselect", selectStationAuto );
  $( "#location-auto").on( "autocompleteselect", selectLocationAuto );
  $( "#channel-auto").on( "autocompleteselect", selectChannelAuto );

  // https://stackoverflow.com/questions/43615966/jquery-ui-autocomplete-match-first-letter-typed
  // Overrides the default autocomplete filter function to search only from the beginning of the string
  $.ui.autocomplete.filter = function (array, term) {
      var matcher = new RegExp("^" + $.ui.autocomplete.escapeRegex(term), "i");
      return $.grep(array, function (value) {
          return matcher.test(value.label || value.value || value);
      });
  };
  
  // Set up datepicker
  // NOTE:  Date object months start with 0, hence the '9-1' notation for September
  options = { minDate: new Date(1975,1-1,1),
              maxDate: 0,
              dateFormat: "yy-mm-dd",
              defaultDate: new Date(2013,9-1,1),
              changeMonth: true,
              changeYear: true,
              onClose: selectStartDate
            }
  $('#datepicker1').datepicker(options);
  
  // get today's date
  var today = new Date();
  // set start date to be a certain number of days earlier
  var yesterday = new Date();
  yesterday.setDate(today.getDate()-14);
  $('#datepicker1').datepicker("setDate",yesterday);

  options = { minDate: new Date(1975,1-1,1),
              maxDate: 0,
              dateFormat: "yy-mm-dd",
              defaultDate: today,
              changeMonth: true,
              changeYear: true,
              onClose: selectEndDate
            }
  $('#datepicker2').datepicker(options);
  $('#datepicker2').datepicker("setDate",today);
  
  // Attach behavior to UI buttons
  $('#previousPlot').click(previousPlot);
  $('#nextPlot').click(nextPlot);
  $('#plotData').click(plotData);

  // Attach behavior to UI selectors
  $('#plotType').change(selectPlotType);
  $('#metric').change(selectMetric);
  
  // Initialize the starttime and endtime fields
  validateDates();

  // Activate tooltips
  $('span.tooltip').cluetip({width: '500px', attribute: 'id', hoverClass: 'highlight'});
  
  // set the initial plot type
  $('#plotType').val("metricTimeseries");

  // Prevent accidental form submission associated with default behavior for buttons
  // https://stackoverflow.com/questions/9347282/using-jquery-preventing-form-from-submitting
  $(document).on("submit", "form", function(e){
    e.preventDefault();
    return  false;
  });

  // Initial web request to discover virtual networks and populate the selector
  // The promise of this function will ajaxUpdateNetworks()
  ajaxUpdateVirtualNetworksSelector();
  
});

