/*
 * Mazama_databrowser.js
 *
 * Jonathan Callahan
 * http://mazamascience.com
 *
 */


/**** GLOBAL VARIABLES ********************************************************/

/****  Here are Mary Templeton's preferred names for metric variables *********
 *
'amplifier_saturation': 'Daily Flag Count: Amplifier Saturation Detected',
'calibration_signal': 'Daily Flag Count: Calibration Signals Present',
'clock_locked': 'Daily Flag Count: Clock locked',
'cross_talk': 'Cross-Talk Check: Channel Cross-Correlation Coefficient',
'data_latency': 'Time Since Last Data Sample Was Acquired',
'dc_offset_times': 'Times of DC Offsets Detected',
'digital_filter_charging': 'Daily Flag Count: Digital Filter Charging',
'digitizer_clipping': 'Daily Flag Count: Digitizer Clipping Detected',
'event_begin': 'Daily Flag Count: Beginning of Event (Trigger)',
'event_end': 'Daily Flag Count: End of Event (Detrigger)',
'event_in_progress': 'Daily Flag Count: Event in Progress',
'feed_latency': 'Time Since Latest Data Was Received',
'glitches': 'Daily Flag Count: Glitches Detected',
'max_gap': 'Daily Maximum Gap Length',
'max_overlap': 'Daily Maximum Overlap Length',
'max_stalta': 'Maximum Daily Short-Term Average/Long-Term Average Amplitude Ratio',
'missing_padded_data': 'Daily Flag instances: Missing/Padded Data Present',
'num_gaps': 'Gaps Per Day',
'num_overlaps': 'Overlaps Per Day',
###'num_spikes': 'Spikes Per Day',
'percent_availability': 'Channel Percent Data Available Per Day',
'pressure_effects': 'Atmospheric Pressure Check: Barometer-Seismometer Cross-Correlation Coefficient',
'sample_max': 'Daily Maximum Amplitude',
'sample_mean': 'Daily Mean Amplitude',
'sample_median': 'Daily Median Amplitude',
'sample_min': 'Daily Minimum Amplitude',
'sample_rms': 'Daily Root Mean Squared Variance of Amplitudes',
'sample_snr': 'P-Wave Signal-To-Noise Ratio',
'spikes': 'Daily Flag Count: Spikes Detected',
'station_completeness': 'Station Percent Data Available Per Day',
'station_up_down_times': 'Station Up/Down Time Spans',
'suspect_time_tag': 'Daily Flag Count: Time Tag Questionable',
'telemetry_sync_error': 'Daily Flag Count: Telemetry Synchronization Error',
'timing_correction': 'Daily Flag Count: Timing Correction Applied',
'timing_quality': 'Daily Average Timing Quality',
'total_latency': 'Total Latency',
'up_down_times': 'Channel Up/Down Time Spans',
*
*/

// TODO:  These lists of metrics might be moved to a separate file to be loaded by the html page. 
// G_multiMetrics just has options
var G_multiMetrics = {'basic_stats':'Min-Max-Mean',
                      'latency':'Latency',
                      'gaps_and_overlaps':'Gaps and Overlaps',
                      'SOH_flags':'State-of-Health flag Counts',
                      'transfer_function':'Transfer function'};

// G_singleMetrics has optgroups and options
var G_singleMetrics = {'simple metrics':{'sample_min': 'Daily Minimum Amplitude',
                                         'sample_max': 'Daily Maximum Amplitude',
                                         'sample_mean': 'Daily Mean Amplitude',
                                         'sample_median': 'Daily Median Amplitude',
                                         'sample_rms': 'Daily Root Mean Squared Variance of Amplitudes',
                                         'num_gaps': 'Gaps Per Day',
                                         'max_gap': 'Daily Maximum Gap Length',
                                         'num_overlaps': 'Overlaps Per Day',
                                         'max_overlap': 'Daily Maximum Overlap Length',
                                         'percent_availability': 'Channel Percent Data Available Per Day',
                                         'data_latency': 'Time Since Last Data Sample Was Acquired',
                                         'feed_latency': 'Time Since Latest Data Was Received',
                                         'total_latency': 'Total Latency'},
                       'transfer function metrics':{'ms_coherence': 'Coherence',
                                                    'gain_ratio': 'Gain Ratio',
                                                    'phase_diff': 'Phase Difference'},
                       'derived metrics':{'max_stalta': 'Maximum Daily STA/LTA Amplitude Ratio',
                                          'sample_unique': 'Daily Count of Unique Sample Values',
                                          'num_spikes': 'Spikes Per Day',
                                          'pct_above_nhnm': 'Percent Above New High Noise Model',
                                          'pct_below_nlnm': 'Percent Below New Low Noise Model',
                                          'dead_channel_exp': 'Dead Channel Metric: Exponential Fit',
                                          'dead_channel_gsn': 'Dead Channel Metric: GSN',
                                          'dead_channel_lin': 'Dead Channel Metric: Linear Fit'},
                       'event based metrics':{//'cross_talk':'Cross Talk',
                                              //'data_resp_gain_ratio':'Data Resp Gain Ratio',
                                              //'data_resp_phase_diff':'Data Resp Phase Diff',
                                              //'magnitude_squared_coherence':'Magnitude Squared Coherence',
                                              //'pressure_effects':'Pressure Effects',
                                              'sample_snr': 'P-Wave Signal-To-Noise Ratio'},
// TODO:  timing_quality is a state-of-health flag and not a daily average
                       'state-of-health flag counts':{'timing_quality': 'Daily Average Timing Quality',
                                                      'amplifier_saturation': 'Daily Flag Count: Amplifier Saturation Detected',
                                                      'calibration_signal': 'Daily Flag Count: Calibration Signals Present',
                                                      'clock_locked': 'Daily Flag Count: Clock locked',
                                                      'digital_filter_charging': 'Daily Flag Count: Digital Filter Charging',
                                                      'digitizer_clipping': 'Daily Flag Count: Digitizer Clipping Detected',
                                                      'event_begin': 'Daily Flag Count: Beginning of Event (Trigger)',
                                                      'event_end': 'Daily Flag Count: End of Event (Detrigger)',
                                                      'event_in_progress': 'Daily Flag Count: Event in Progress',
                                                      'missing_padded_data': 'Daily Flag instances: Missing/Padded Data Present',
                                                      'suspect_time_tag': 'Daily Flag Count: Time Tag Questionable',
                                                      'telemetry_sync_error': 'Daily Flag Count: Telemetry Synchronization Error',
                                                      'timing_correction': 'Daily Flag Count: Timing Correction Applied'}
                      };

// G_networks is defined in networks.js which is loaded by the html page.
// SNCL selector associative arrays are load by the html page:  G_networks, G_stations, G_locations, G_channels

var G_firstPlot = true;

var G_network = "IU";
var G_station = "ANMO";
var G_location = "00";
var G_channel = "BHZ";

var G_singleMetric = 'sample_rms';
var G_multiMetric = 'basic_stats';

var G_loadSecs;
var G_plotSecs;
var G_RSecs;


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


// Generate Network selector ---------------------------------------------------

function generateNetworks(){
  // Get the list of options
  var options = G_networks

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

  // Reset the gobal network in case anything changed
  G_network = $('#network').val(); // TODO:  This is removed in Robert's version
  
  generateStations();
}


// Generate Station selector ---------------------------------------------------

function generateStations(){
  // Get the list of options
  var options = G_stations[G_network].sort();

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
  
  // Reset the gobal station in case anything changed
  G_station = $('#station').val(); // TODO:  This is removed in Robert's version
  
  generateLocations();
}


// Generate Locations selector -------------------------------------------------

function generateLocations(){
  // Get the list of options
  var netSta = G_network + '.' + G_station;
  var options = G_locations[netSta].sort();

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
  
  // Reset the gobal location in case anything changed
  G_location = $('#location').val();
  
  generateChannels();
}

// Generate Channels selector --------------------------------------------------

function generateChannels(){
  // Get the list of options
  var netStaLoc = G_network + '.' + G_station + '.' + G_location;
  var options = G_channels[netStaLoc].sort();
  
  // Empty the selector
  var sel = $('#channel');
  sel.empty();
  
  for (var i=0; i<options.length; i++) {
    if (options[i] == G_channel) {
      sel.append('<option selected="selected" value="' + options[i] + '">' + options[i] + '</option>');
    } else {
      sel.append('<option value="' + options[i] + '">' + options[i] + '</option>');
    }
  }

  // Reset the gobal channel in case anything changed
  G_channel = $('#channel').val();

  if (G_firstPlot) {
    updatePlot();
    G_firstPlot = false;
  }
}

// Set the global channel variable ---------------------------------------------

function selectChannel(){
  G_channel = $('#channel').val();
}


/**** PREV/NEXT STATION BUTTONS ***********************************************/

// Figure out the index of the currently selected station and decrement if possible
function prevStation() {

  var plotType = $('#plotType').val();

  if (plotType == 'networkBoxplot') {
    var currentOption = $('#network').val();
    var allOptions = $('#network option').map(function() {return $(this).val();}).get();
  } else {
    var currentOption = $('#station').val();
    var allOptions = $('#station option').map(function() {return $(this).val();}).get();
  }

  var index = 0;
  for (i=0; i<allOptions.length; i++) {
    if (allOptions[i] == currentOption) {
      index = i;
      break;
    }
  }

  if (index == 0) {
    $('#prevStation').prop('disabled',true);
  } else {
    index--;
    if (plotType == 'networkBoxplot') {
      G_network = allOptions[index];
      $('#network').val(G_network);
    } else {
      G_station = allOptions[index];
      $('#station').val(G_station);
    }
  }

  $('#nextStation').prop('disabled',false);

  updatePlot();
}


// Figure out the index of the currently selected station and increment if possible
function nextStation() {

  var plotType = $('#plotType').val();

  if (plotType == 'networkBoxplot') {
    var currentOption = $('#network').val();
    var allOptions = $('#network option').map(function() {return $(this).val();}).get();
  } else {
    var currentOption = $('#station').val();
    var allOptions = $('#station option').map(function() {return $(this).val();}).get();
  }

  var index = 0;
  for (i=0; i<allOptions.length; i++) {
    if (allOptions[i] == currentOption) {
      index = i;
      break;
    }
  }

  if (index == allOptions.length-1) {
    $('#nextStation').prop('disabled',true);
  } else {
    index++;
    if (plotType == 'networkBoxplot') {
      G_network = allOptions[index];
      $('#network').val(G_network);
    } else {
      G_station = allOptions[index];
      $('#station').val(G_station);
    }
  }

  $('#prevStation').prop('disabled',false);

  updatePlot();
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
}


// Reset styles, enable disabled elements, etc.
function postPlotActions(JSONResponse) {
  $('#spinner').hide();
  $('#profiling_container').show();
  $('#dataLink_container').show();
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


/**** REQUEST HANDLERS ********************************************************/

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
  $('#network').change(generateStations);
  $('#station').change(generateLocations);
  $('#location').change(generateChannels);
  $('#channel').change(selectChannel);
  
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
  
  // Initial population of the SNCL selectors (which will generate a request)
  generateNetworks();

  // set the initial plot type
  $('#plotType').val("metricTimeseries");

});

