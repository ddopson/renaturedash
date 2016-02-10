window.UNITS =
UNITS = {
  TempF: (val) -> "<b>#{val.toFixed(2)}</b>F (<b>#{((val - 32) * 5 / 9).toFixed(2)}</b>C)"
  Gal: (val) -> "<b>#{val.toFixed(1)}</b>Gal (<b>#{(val*3.7854118).toFixed(0)}</b>L)"
  Pct: (val) -> "<b>#{val.toFixed(2)}</b>%"
}

window.METRICS =
METRICS = [
  {
    metric:'R1_TOP_AVG_CAL'
    name: 'Reactor Temp1'
    units: UNITS.TempF
  },{
    metric:'R1_BOT_AVG_CAL'
    name: 'Reactor Temp2'
    units: UNITS.TempF
  },{
    metric:'T1_VOLUME'
    name: 'Rector Volume'
    scale: 0.1
    units: UNITS.Gal
  },{
    metric:'R2_BOT_AVG_CAL'
    name: 'Ambient Temp'
    units: UNITS.TempF
  },{
    metric:'R1_MID_AVG_CAL'
    name: 'Heat Xchange Temp'
    units: UNITS.TempF
  },{
    metric:'HEATER_OUTPUT_AVERAGE'
    name: '% Heater Load'
    units: UNITS.Pct
  }
]

window.chartOptions =
chartOptions =
  rangeSelector:
    buttons: [
      {type: 'hour', count: 6, text: '6h'}
      {type: 'day', count: 1, text: '1d'}
      {type: 'week', count: 1, text: '1w'}
      {type: 'month', count: 1, text: '1m'}
      {type: 'month', count: 3, text: '3m'}
      {type: 'all', count: 1, text: 'All'}
    ]
    inputBoxWidth: 130
    inputDateFormat: '%Y-%m-%d %H:%M'
    inputEditDateFormat: '%Y-%m-%d %H:%M'
    selected: 0
  title:
    text: 'Temperatures'
  tooltip:
    pointFormatter: () ->
      point = this
      y = point.y
      opts = point.series.options
      if (opts.scale)
        y /= opts.scale
      valstr = opts.units(y)
      return """<span style="color:#{point.color}">\u25CF</span> #{opts.name}: #{valstr}<br/>"""
  series: METRICS
  yAxis:
    min: 40.0
    max: 180.0

window.$(()->
  n_done = 0
  console.log("Fetching data")
  $.each(METRICS, (i, thing) ->
    $.getJSON('/data.jsonp?metric=' + thing.metric + '&callback=?', (data) ->
      console.log("Has data: ", thing.metric)
      if thing.scale
        for _, idx in data
          data[idx][1] *= thing.scale
      thing.data = data
      if (++n_done == METRICS.length)
        createChart()
    )
  )

  $('body').append($('<div id="series-selector"></div>'))
  
  html = ""
  for el in METRICS
    html += '<input type="checkbox" id="'+el.metric+'">'+el.metric+'</input><br>'

  $('#container').height('600px')
  Highcharts.setOptions(
    global:
      useUTC: false
  )
)

$('body').append('<div id="current_data"></div>')

window.createChart = () ->
  console.log "CREATE_CHART"
  $('#container').highcharts('StockChart', chartOptions)
  $('#export').append('<button type="button">Generate CSV Export</button>')
  $('#export').append('<div id="download_link"></div>')
  $('#export button').click(make_download)

  text = "<table>"
  window.chart = $('#container').highcharts()
  for m, idx in METRICS
    [t, v] = m.data[m.data.length - 1]
    if (m.scale)
      v /= m.scale
    valstr = m.units(v)
    valstr = valstr.replace('(', '</td><td>').replace(')', '')
    color = chart.series[idx].color
    text += """<tr><td>#{fmt_time(t)}</td><td><span style="color:#{color}">\u25CF</span> #{m.name}</td><td>#{valstr}</td></tr>"""
  text += "</table>"
  $('#current_data').html(text)
  



window.make_csv =
make_csv = (tstart, tend) ->
  csv = {}
  for s, idx in METRICS
    for [time, val] in s.data when time >= tstart and time <= tend
      csv[time] ||= []
      csv[time][idx] = val
  names = [s.name for s in METRICS]
  text = "DateTime,#{names.join(",")}\n"
  for t in Object.keys(csv).sort()
    d = new Date(+t)
    tstr = """#{d.toDateString()} #{d.toTimeString()}"""
    text += "#{tstr},#{csv[t].join(",")}\n"
  return text

window.fmt_time =
fmt_time = (t) ->
  d = new Date(t)
  return """#{d.getFullYear()}-#{d.getMonth()+1}-#{d.getDate()}T#{d.getHours()}-#{d.getMinutes()}"""

window.make_download =
make_download = () ->
  console.log "MAKING_DOWNLOAD"
  chart = $('#container').highcharts()
  [tstart, tend] = [chart.axes[0].min, chart.axes[0].max]
  text = make_csv(tstart, tend)
  blob = new Blob([text], {type: 'application/octet-stream .csv'})
  url = URL.createObjectURL(blob)
  $('#download_link').html("""<a href="#{url}" download="metrics-#{fmt_time(tstart)}--to--#{fmt_time(tend)}.csv">Download metrics.csv</a>""")

