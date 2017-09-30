/*
 * Mazama_databrowser.js
 *
 * Jonathan Callahan
 * http://mazamascience.com
 *
 */


/**** GLOBAL VARIABLES ********************************************************/

/****  Here are Gillian's 2017-08-15 preferred names for metric variables *********

simple metrics (daily)
  max_gap: maximum gap duration
  max_overlap: maximum overlap duration
  max_stalta: maximum STA/LTA amplitude ratio
  num_gaps: number of gaps
  num_overlaps: number of overlaps
  num_spikes: number of spikes detected
  percent_availability: percentage data available
  sample_min: minimum amplitude
  sample_max: maximum amplitude
  sample_mean: mean amplitude
  sample_median: median amplitude
  sample_rms: root-mean- square variance of amplitudes
  sample_unique: count of unique sample values
latency metrics
  data_latency: time between latest data acquisition and receipt
  feed_latency: time since latest data was received
  total_latency: total data latency
PSD metrics (daily)
  dead_channel_exp: residuals of exponential fit to PSD mean
  dead_channel_gsn: TRUE/FALSE
  dead_channel_lin: residuals of linear fit to PSD mean
  pct_above_nhnm: percent of PDF matrix above New High Noise Model
  pct_below_nlnm: percent of PDF matrix below New Low Noise Model
event based metrics
  cross_talk: channel cross-correlation
  polarity_check: near neighbor station cross-correlation
  sample_snr: P-wave signal-to- noise ratio
transfer function metrics
  ms_coherence: coherence
  gain_ratio: gain ratio
  phase_diff: phase difference
miniSEED state-of- health metrics (daily flag count)
  amplifier_saturation: amplifier saturation detected
  calibration_signal: calibration signals present
  clock_locked: clock locked
  digital_filter_charging: digital filter may be charging
  digitizer_clipping: digitizer clipping detected
  event_begin: beginning of an event, station trigger
  event_end: end of an event, station detrigger
  glitches: glitches detected
  missing_padded_data: missing/padded data present
  spikes: spikes detected
  suspect_time_tag: time tag is questionable
  telemetry_sync_error: telemetry synchronization error
  timing_correction: time correction applied
miniSEED state-of- health metrics (other)
  timing_quality: average timing quality

*/

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

// NOTE:  Configurable list of channels curently in the MUSTANG database
var G_mustangChannels = "CH?,DH?,LH?,MH?,SH?,EH?,EL?,BN?,HN?,LN?,BY?,DP?,BH?,HH?,BX?,HX?,VM?";

// SNCL selector arrays 
var G_virtualNetworks = [];
var G_networks = DEFAULT_networks;                // DEFAULT_networks is defined in networks.js
var G_stations = DEFAULT_stations;                // DEFAULT_stations is defined in stations.js
var G_locations = DEFAULT_locations;              // DEFAULT_locations is defined in locations.js
var G_channels = DEFAULT_channels;                // DEFAULT_channels is defined in channels.js

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

// state flag
var G_firstPlot = true;

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
    $('#prevStation').prop('title','use previous station');
    $('#nextStation').prop('title','use next station');

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

  } else if (plotType == 'stackedMetricTimeseries') {

    // Metric
    generateMultiMetricsSelector();
    $('#metric').removeClass('doNotSerialize').show();

    // Plot Buttons
    $('#prevStation').prop('title','use previous station');
    $('#nextStation').prop('title','use next station');

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

  } else if (plotType == 'networkBoxplot') {

    // Metric
    generateSingleMetricsSelector();
    $('#metric').removeClass('doNotSerialize').show();

    // Plot Buttons
    $('#prevStation').prop('title','use previous network');
    $('#nextStation').prop('title','use next network');

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
    // TODO:  We may wish to query the stations webservice when this happens to
    // TODO:  get a complete list of locations and channels
    $('#network').removeClass('doNotSerialize');
    $('#station').addClass('doNotSerialize');
    $('#location').removeClass('doNotSerialize').show();
    $('#channel').removeClass('doNotSerialize').show();

  } else if (plotType == 'stationBoxplot') {

    // Metric
    generateSingleMetricsSelector();
    $('#metric').removeClass('doNotSerialize').show();

    // Plot Buttons
    $('#prevStation').prop('title','use previous station');
    $('#nextStation').prop('title','use next station');

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

  } else if (plotType == 'trace' ||
             plotType == 'pdf') {

    // Metric
    $('#metric').addClass('doNotSerialize').hide();

    // Plot Buttons
    $('#prevStation').prop('title','use previous station');
    $('#nextStation').prop('title','use next station');

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

  } 

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
  options.splice(0,0,"No virtual network");

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

function generateNetworksSelector(){
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

 // If the current station is not in the network, choose the first available
  var N = G_network;
  var allStations = G_stations[N].sort();
  if (allStations.indexOf(G_station) < 0) {
    G_station = allStations[0];
  } 

  // Update the associated autocomplete box
  $("#network-auto").autocomplete({source: options});
  $("#network-auto").val("");
 
  generateStationsSelector();
}


// Generate Station selector ---------------------------------------------------

function generateStationsSelector(){
  // Get the list of options
  var options = G_stations[G_network].sort();

  // If the current station is not in the network, choose the first available
  if (options.indexOf(G_station) < 0) {
    G_station = options[0];
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
  
 // If the current location is not in the station, choose the first available
  var NS = G_network + '.' + G_station;
  var allLocations = G_locations[NS].sort();
  if (allLocations.indexOf(G_location) < 0) {
    G_location = allLocations[0];
  } 
  
  // Update the associated autocomplete box
  $("#station-auto").autocomplete({source: options});
  $("#station-auto").val("");
 
  generateLocationsSelector();
}


// Generate Locations selector -------------------------------------------------

function generateLocationsSelector(){
  // Get the list of options
  var NS = G_network + '.' + G_station;
  var options = G_locations[NS].sort();

  // If the current location is not in the station, choose the first available
  if (options.indexOf(G_location) < 0) {
    G_location = options[0];
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
  
 // If the current channel is not in the location, choose the first available
  var NSL = G_network + '.' + G_station + '.' + G_location;
  var allChannels = G_channels[NSL].sort();
  if (allChannels.indexOf(G_channel) < 0) {
    G_channel = allChannels[0];
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
  
  // If the current location is not in the station, choose the first available
  if (options.indexOf(G_channel) < 0) {
    G_channel = options[0];
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

  if (G_firstPlot) {
    updatePlot();
    G_firstPlot = false;
  }

    // Update the associated autocomplete box
  $("#channel-auto").autocomplete({source: options});
  $("#channel-auto").val("");
 
}

// Set the global channel variable from selector -------------------------------

function selectVirtualNetwork(){
  G_previousVirtualNetwork = G_virtualNetwork;
  G_virtualNetwork = $('#virtualNetwork').val();
  updateSNCLSelectors();
}

function selectNetwork(){
  G_network = $('#network').val();
  generateNetworksSelector();
}

function selectStation(){
  G_station = $('#station').val();
  generateStationsSelector();
}

function selectLocation(){
  G_location = $('#location').val();
  generateLocationsSelector();
}

function selectChannel(){
  G_channel = $('#channel').val();
  generateChannelsSelector();
}

// Set the global channel variable from auto-complete box ----------------------

function selectNetworkAuto(event, ui){
  G_network = ui.item.value;
  generateNetworksSelector();
}

function selectStationAuto(event, ui){
  G_station = ui.item.value;
  generateStationsSelector();
}

function selectLocationAuto(event, ui){
  G_location = ui.item.value;
  generateLocationsSelector();
}

function selectChannelAuto(event, ui){
  G_channel = ui.item.value;
  generateChannelsSelector();
}


/**** PREV/NEXT STATION BUTTONS ***********************************************/

// Move to the previous available location/station that shares the current channel
function prevStation() {

  var plotType = $('#plotType').val();

  if (plotType == 'networkBoxplot') {

    // networkBoxplots increment the network

    var currentNetwork = $('#network').val();
    var allNetworks = $('#network option').map(function() {return $(this).val();}).get();
    var networkIndex = allNetworks.indexOf(currentNetwork);
    if (networkIndex == 0) {
      $('#prevStation').prop('disabled',true);
    } else {
      networkIndex--;
      G_network = allNetworks[networkIndex];
      generateNetworksSelector(); // trigger the cascading selectors
      $('#nextStation').prop('disabled',false);
      updatePlot();
      return;
    }

  } else {

    // all other plot types decrement the location and then the station

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

    var stationIndex = allStations.indexOf(currentStation);
    var locationIndex = allLocations.indexOf(currentLocation);

    // Try to decrement the location if possible
    while (locationIndex > 0) {

      locationIndex--;
      NSL = currentNetwork + '.' + currentStation + '.' + allLocations[locationIndex];
      allChannels = G_channels[NSL].sort();
      if (allChannels.indexOf(currentChannel) >= 0) {
        G_location = allLocations[locationIndex];
        generateLocationsSelector(); // trigger the cascading selectors
        $('#prevStation').prop('disabled',false);
        updatePlot();
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
          G_station = currentStation;
          G_location = allLocations[locationIndex];
          generateStationsSelector(); // trigger the cascading selectors
          $('#nextStation').prop('disabled',false);
          updatePlot();
          return;
        } 

      } // END locationIndex while loop

    } // END stationIndex while loop

  } // END plotType

}


// Move to the next available location/station that shares the current channel
function nextStation() {

  var plotType = $('#plotType').val();

  if (plotType == 'networkBoxplot') {

    // networkBoxplots increment the network

    var currentNetwork = $('#network').val();
    var allNetworks = $('#network option').map(function() {return $(this).val();}).get();
    var networkIndex = allNetworks.indexOf(currentNetwork);
    if (networkIndex == allNetworks.length-1) {
      $('#nextStation').prop('disabled',true);
      return;
    } else {
      networkIndex++;
      G_network = allNetworks[networkIndex];
      generateNetworksSelector(); // trigger the cascading selectors
      $('#prevStation').prop('disabled',false);
      updatePlot();
      return;
    }

  } else {

    // all other plot types increment the location and then the station

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

    var stationIndex = allStations.indexOf(currentStation);
    var locationIndex = allLocations.indexOf(currentLocation);

    // Try to increment the location if possible
    while (locationIndex < allLocations.length-1) {

      locationIndex++;
      NSL = currentNetwork + '.' + currentStation + '.' + allLocations[locationIndex];
      allChannels = G_channels[NSL].sort();
      if (allChannels.indexOf(currentChannel) >= 0) {
        G_location = allLocations[locationIndex];
        generateLocationsSelector(); // trigger the cascading selectors
        $('#prevStation').prop('disabled',false);
        updatePlot();
        return;
      } 

    }

    // If we have run out of locations, try to increment the station
    while (stationIndex < allStations.length-1) {

      stationIndex++;
      currentStation = allStations[stationIndex];
      NS = currentNetwork + '.' + currentStation;
      allLocations = G_locations[NS].sort();
      locationIndex = -1;

      while (locationIndex < allLocations.length) {

        locationIndex++;
        NSL = currentNetwork + '.' + currentStation + '.' + allLocations[locationIndex];
        allChannels = G_channels[NSL].sort();

        if (allChannels.indexOf(currentChannel) >= 0) {
          G_station = currentStation;
          G_location = allLocations[locationIndex];
          generateStationsSelector(); // trigger the cascading selectors
          $('#prevStation').prop('disabled',false);
          updatePlot();
          return;
        } 

      } // END locationIndex while loop

    } // END stationIndex while loop

  } // END plotType

}


/**** EVENT HANDLERS **********************************************************/

// One layer of abstraction before sending the request allows us to take UI
// specific actions, e.g. setting hidden parameters or disabling some elements,
// before sending the request.
function updatePlot() {

  var dayCount = createTimeSpan();

/***** IGNORE THESE FOR NOW
  if ( $('#plotType').val() == 'networkBoxplot' && $('#network').val() == 'IU' && dayCount > 190 ) {
    alert("Network Boxplots for the IU network download a lot of data. Please choose a timespan <= 6 months.");
  } else if ( $('#plotType').val() == 'trace' && $('#channel').val()[0] == 'L' && dayCount > 7 ) {
    alert("Seismic Trace plots download a lot of data. Please choose a timespan <= 7 days for L channels.");
  } else if ( $('#plotType').val() == 'trace' && $('#channel').val()[0] != 'L' && dayCount > 1 ) {
    alert("Seismic Trace plots download a lot of data. Please choose a timespan = 1 day for non-L channels.");
  } else if ( $('#plotType').val() == 'pdf' && $('#channel').val()[0] == 'L' && dayCount > 7 ) {
    alert("Seismic PDF plots download a lot of data. Please choose a timespan <= 7 days for L channels.");
  } else if ( $('#plotType').val() == 'pdf' && $('#channel').val()[0] != 'L' && dayCount > 1 ) {
    alert("Seismic PDF plots download a lot of data. Please choose a timespan = 1 day for non-L channels.");
  } else { 
**/

    prePlotActions();
    sendRequest();

/**
  }
**/
}


// Set styles, disable elements, etc.
function prePlotActions() {
  $('#spinner').fadeIn(1000);
  $('#profiling_container').hide();
  $('#dataLink_container').hide();
  $('#requestMessage').removeClass('alert').text('');
  $('#activityMessage').text("plot request").addClass("info");

}


// Reset styles, enable disabled elements, etc.
function postPlotActions(JSONResponse) {
  $('#spinner').hide();
  $('#profiling_container').show();
  $('#dataLink_container').show();
  $('#activityMessage').text("").removeClass("info");
}


// Set up time span 
function createTimeSpan() {
  var startDate = $('#datepicker1').datepicker("getDate");
  var endDate = $('#datepicker2').datepicker("getDate");

  // Sanity check
  if (endDate < startDate) {
    alert("End date < start date! Resetting end date.");
    endDate = new Date(startDate);
    endDate.setDate(endDate.getDate() + 1);
    $('#datepicker2').datepicker("setDate",endDate);
  }

  var timeDiff = Math.abs(endDate.getTime() - startDate.getTime());
  var dayCount = Math.ceil(timeDiff / (1000 * 3600 * 24)); 
  var starttimeString = $.datepicker.formatDate('yy-mm-dd',startDate);
  var endtimeString = $.datepicker.formatDate('yy-mm-dd',endDate);
  $('#starttime').val(starttimeString);
  $('#endtime').val(endtimeString);

  return(dayCount)
}


/**** CGI REQUEST HANDLER *****************************************************/

// Serialize the form and send it to the CGI.
// Note that some UI elements have no bearing on the product generated and
// should be removed from the request to improve our cache hit rate.
function sendRequest() {
  var url = '/cgi-bin/__DATABROWSER__.cgi';
  var data = $('#controls_form').serialize();
  var removeList = $('.doNotSerialize');
  for (i=0; i<removeList.length; i++) {
     var valueString = $(removeList[i]).serialize();
     if (valueString != '') {
       var removeString = '&' + valueString;
       data = data.replace(removeString,'');
     }
  }
  // Special handling for timseriesChannelSet option -- 10/31/2016
  // Make the last character a question mark.
  if ($('#timeseriesChannelSet').prop('checked') &&
      !$('#timeseriesChannelSet').hasClass('doNotSerialize')) {
    var channelString = "channel=" + $('#channel').val();
    var chasetString = "channel=" + $('#channel').val().substr(0,2) + "?";
    data = data.replace(channelString,chasetString);
  }
  //  DEBUG
  //displayError("url: " + url + ", data: " + data);
  $.getJSON(url, data, handleJSONResponse);
}


function handleJSONResponse(JSONResponse) {
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
  postPlotActions();
}

/**** IRIS WEBSERVICE HANDLERS ************************************************/

// Get a list of virtual network codes and repopulate the virtual networks selector
function updateVirtualNetworksSelector() {
  var url = 'http://service.iris.edu/irisws/virtualnetwork/1/codes'; // response is always XML
  $.get(url, function(serviceResponse) {
      // NOTE:  This function is a 'promise' that gets evaluated asynchronously
      // NOTE:  https://api.jquery.com/jquery.get/
      var vnetNodes = serviceResponse.getElementsByTagName("virtualNetwork");
      var vnetCodes = $.map(vnetNodes, function(elem, i) { return(elem.getAttribute("code")); } );
      // var vnetDescriptions = $.map(vnetNodes, function(elem, i) { return(elem.firstElementChild.textContent); } );
      G_virtualNetworks = vnetCodes;
    }
  ).done(function() {
    generateVirtualNetworksSelector(); // based on the values in G_virtualNetworks
  });
  // Can be chained with .done().fail().always() 
}

// Query for station metadata in for this virtual network and repopulate all SNCL selectors
function updateSNCLSelectors() {
  if (G_virtualNetwork == "No virtual network") {
    G_networks = DEFAULT_networks;
    G_stations = DEFAULT_stations;
    G_locations = DEFAULT_locations;
    G_channels = DEFAULT_channels;
    generateNetworksSelector();
    return;
  }

  // UI cues
  $('#profiling_container').hide();
  $('#dataLink_container').hide();
  $('#activityMessage').text("service.iris.edu/fdsnws/station/1/query").addClass("info");

  var url = 'http://service.iris.edu/fdsnws/station/1/query';
  var data = {net:G_virtualNetwork,
              sta:"*",
              loc:"*",
              cha:G_mustangChannels,
              starttime:$('#starttime').val(),
              endtime:$('#endtime').val(),
              level:"channel",
              nodata:"404",
              format:"text"};
  $.get(url, data, function (serviceResponse) {

    $('#activityMessage').text("building selectors");

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
    var Ns = $.map(data, function(row, i) { return(row[0]); } );
    var NSs = $.map(data, function(row, i) { return(row[0] + '.' + row[1]); } );
    var NSLs = $.map(data, function(row, i) { return(row[0] + '.' + row[1] + '.' + row[2]); } );
    var NSLCs = $.map(data, function(row, i) { return(row[0] + '.' + row[1] + '.' + row[2] + '.' + row[3]); } );

    // Create unique arrays
    var uniqueNs = Ns.filter(function(val, i) { return(Ns.indexOf(val)==i); }).sort();
    var uniqueNSs = NSs.filter(function(val, i) { return(NSs.indexOf(val)==i); }).sort();
    var uniqueNSLs = NSLs.filter(function(val, i) { return(NSLs.indexOf(val)==i); }).sort();
    var uniqueNSLCs = NSLCs.filter(function(val, i) { return(NSLCs.indexOf(val)==i); }).sort();

    // Replace the G_networks array
    G_networks = uniqueNs;

    // Replace the G_stations "station by network" associative array
    G_stations = {};
    $.each(uniqueNs, function(i, N) {
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
    
    var a = 1;

  }).done(function(serviceResponse) {

    // Regenerate all selectors based on the new G_~ arrays
    generateNetworksSelector();


  }).fail(function(serviceResponse) {

    if (serviceResponse.status == 404) {
      // Service returned "no data found" -- possibly due to an inappropriate time range
      alert("No station metadata found for the selected virtual network and time range.");
    }
    // Restore previous virtual network selection
    G_virtualNetwork = G_previousVirtualNetwork;
    generateVirtualNetworksSelector(); // based on the values in G_virtualNetworks   

  }).always(function() {

    $('#activityMessage').text("").removeClass("info");
    // $('#profiling_container').show();
    // $('#dataLink_container').show();

  });

}


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
  
  // Set up datepicker
  // NOTE:  Date object months start with 0, hence the '9-1' notation for September
  options = { minDate: new Date(1975,1-1,1),
              maxDate: 0,
              dateFormat: "yy-mm-dd",
              defaultDate: new Date(2013,9-1,1),
              changeMonth: true,
              changeYear: true
            }
  $('#datepicker1').datepicker(options);
  //$('#datepicker1').datepicker("setDate","2013-09-01");
  
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
              changeYear: true
            }
  $('#datepicker2').datepicker(options);
  $('#datepicker2').datepicker("setDate",today);
  
  // Attach behavior to UI elements
  $('#prevStation').click(prevStation);
  $('#nextStation').click(nextStation);
  $('#plotData').click(updatePlot);
  $('#plotType').change(selectPlotType);
  $('#metric').change(selectMetric);
  
  // Initialize time span
  var dayCount = createTimeSpan();

  // Activate tooltips
  $('span.tooltip').cluetip({width: '500px', attribute: 'id', hoverClass: 'highlight'});
  
  // set the initial plot type
  $('#plotType').val("metricTimeseries");

  // Initial web request to discover virtual networks and populate the selector
  updateVirtualNetworksSelector();
  
  // Initial population of the SNCL selectors (which will generate a request)
  generateNetworksSelector();

  // set the initial plot type
  $('#plotType').val("metricTimeseries");

});

