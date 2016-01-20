var METRICS = [
  {
    metric:'R1_TOP_AVG_CAL',
    name: 'Reactor Temp1',
    show_celcius: true
  },{
    metric:'R1_BOT_AVG_CAL',
    name: 'Reactor Temp2',
    show_celcius: true
  },{
    metric:'T1_VOLUME',
    name: 'Rector Volume',
    scale: 0.1,
    units: 'Gal'
  },{
    metric:'R2_BOT_AVG_CAL',
    name: 'Ambient Temp',
    show_celcius: true
  },{
    metric:'R1_MID_AVG_CAL',
    name: 'Heat Xchange Temp',
    show_celcius: true
  },{
    metric:'HEATER_OUTPUT_AVERAGE',
    name: '% Heater Load',
    units: '%'
  }
]

var chartOptions = {
  rangeSelector: {
    buttons: [
      {type: 'hour', count: 6, text: '6h'},
      {type: 'day', count: 1, text: '1d'},
      {type: 'week', count: 1, text: '1w'},
      {type: 'month', count: 1, text: '1m'},
      {type: 'month', count: 3, text: '3m'},
      {type: 'all', count: 1, text: 'All'}
    ],
    inputBoxWidth: 130,
    inputDateFormat: '%Y-%m-%d %H:%M', //%b %e %Y %H:%M',
    inputEditDateFormat: '%Y-%m-%d %H:%M',
    selected: 1
  },
  title: { text: 'Temperatures'},
  tooltip: {
    pointFormatter: function() {
      var point = this;
      window.last_point = point;
      var y = point.y;
      var opts = point.series.options;
      if (opts.scale) {
        y /= opts.scale
      }
      var valstr = '<b>'+y.toFixed(2)+'</b>'
      if (opts.units) {
        valstr += opts.units
      }
      if (opts.show_celcius) {
        valstr += 'F (<b>'+ ((y - 32) * 5 / 9).toFixed(2)+'</b>C)'
      }
      return '<span style="color:'+point.color+'">\u25CF</span> '+opts.name+': '+
          valstr +'<br/>'
    }
  },
  series: METRICS,
  yAxis: {
    min: 40.0,
    max: 180.0
  }
}

$(function () {
  var n_done = 0;
  console.log("Fetching data")
  $.each(METRICS, function (i, thing) {
    $.getJSON('/data.jsonp?metric=' + thing.metric + '&callback=?', function (data) {
      console.log("Has data: ", thing.metric)
      if (thing.scale) {
        for (k in data) {
          data[k][1] *= thing.scale
        }
      }
      thing.data = data
      if (++n_done === METRICS.length) {
        createChart();
      }
    });
  });

  $('body').append($('<div id="series-selector"></div>'))
  
  html = ""
  for (idx in METRICS) {
    el = METRICS[idx].metric
    html += '<input type="checkbox" id="'+el+'">'+el+'</input><br>'
  }

  $('#container').height('600px')
  Highcharts.setOptions({
    global: {
      //timezoneOffset: -3*60,
      useUTC: false
    }
  })
  $('#export').append('<button type="button">Generate CSV Export</button>')
  $('#export').append('<div id="download_link"></div>')
  $('#export button').click(make_download)
});

function createChart() {
  console.log("CREATE_CHART")
  $('#container').highcharts('StockChart', chartOptions)
}

function make_csv(tstart, tend) {
  //make_csv = (tstart, tend) ->
  //  csv = {}
  //  for s, idx in seriesOptions
  //    for [time, val] in s.data when time >= tstart and time <= tend
  //      csv[time] ||= []
  //      csv[time][idx] = val
  //  names = [s.name for s in seriesOptions]
  //  text = "DateTime,#{names.join(",")}\n"
  //  for t in Object.keys(csv).sort()
  //    tstr = (new Date(+t)).toISOString() 
  //    text += "#{tstr},#{csv[t].join(",")}\n"
  //  return text
  var csv, i, idx, j, k, len, len1, len2, names, ref, ref1, ref2, s, t, text, time, tstr, val;
  csv = {};
  for (idx = i = 0, len = seriesOptions.length; i < len; idx = ++i) {
    s = seriesOptions[idx];
    ref = s.data;
    for (j = 0, len1 = ref.length; j < len1; j++) {
      ref1 = ref[j], time = ref1[0], val = ref1[1];
      if (!(time >= tstart && time <= tend)) {
        continue;
      }
      csv[time] || (csv[time] = []);
      csv[time][idx] = val;
    }
  }
  names = [
    (function() {
      var k, len2, results;
      results = [];
      for (k = 0, len2 = seriesOptions.length; k < len2; k++) {
        s = seriesOptions[k];
        results.push(s.name);
      }
      return results;
    })()
  ];
  text = "DateTime," + (names.join(",")) + "\n";
  ref2 = Object.keys(csv).sort();
  for (k = 0, len2 = ref2.length; k < len2; k++) {
    t = ref2[k];
    tstr = (new Date(+t)).toISOString();
    text += tstr + "," + (csv[t].join(",")) + "\n";
  }
  return text;
};


function make_download() {
  var chart = $('#container').highcharts()
  var text = make_csv(chart.axes[0].min, chart.axes[0].max)
  var blob = new Blob([text], {type: 'text/plain'})
  var url = URL.createObjectURL(blob)
  $('#download_link').html('<a href="'+url+'" download="metrics.csv">Download metrics.csv</a>')
}
