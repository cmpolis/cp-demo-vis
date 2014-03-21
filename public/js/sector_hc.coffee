#
# Chris Polis, 2014

#
seriesCache = {}
colors =
  white:  '#EEE'
  med:    '#555'
  dark:   '#444'
  bg:     '#262626'
  series: '#E5B56E #EDB09B #90E0DB #D5D677 #E5B2C2 #CED4CF #99CDE2 #8EDEB8'.split ' '
months = 'Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec'.split ' '
estFix = 5 * 60 * 60 * 1000
graph  = null
series = null

# 
setStyles = () ->
  Highcharts.setOptions
    colors: colors.series
    textColor: colors.white
    chart:
      backgroundColor: colors.bg
    xAxis:
      tickColor: colors.med
      labels:
        style:
          color: colors.white
          fontWeight: 'bold'
    yAxis:
      gridLineColor: colors.med
      minorGridLineColor: colors.dark
      labels:
        style:
          color: colors.white
          fontWeight: 'bold'
    labels:
      style:
        color: colors.white
    tooltip:
      backgroundColor: colors.dark
      style:
        color: colors.white
    toolbar:
      itemStyle:
        color: colors.white
    rangeSelector:
      labelStyle:
        color: colors.white
      inputStyle:
        backgroundColor: colors.dark
        color: colors.white

# Load price JSON or load from cache
loadPriceData = (sectors) =>
  series = []

  for sector in sectors
    if seriesCache[sector]
      series.push seriesCache[sector]
      buildGraph(series) if series.length == sectors.length

    else
      prices = $.getJSON "/sector/#{sector}/prices.json", (priceData) ->
        newSeries = { name: decodeURIComponent(sector), data: priceData }
        seriesCache[sector] = newSeries
        series.push newSeries
        buildGraph(series) if series.length == sectors.length

#
buildExtremesTable = (evt) =>
  tbody = $('#extremes-table tbody').html ''

  sectorData = graph.series.filter((d) -> d.name != 'Navigator')
  for sd in sectorData
    maxData = sd.data.filter((d) -> d.change == sd.dataMax)[0]
    minData = sd.data.filter((d) -> d.change == sd.dataMin)[0]
    console.log maxData
    tbody.append "
      <tr style='color:#{sd.color}'>
        <td>#{sd.name}</td>
        <td>#{if maxData.change > 0 then '+' else ''}#{maxData.change.toFixed(3)}</td>
        <td>#{maxData.y.toFixed(2)}</td>
        <td>#{new Date(maxData.x + estFix).toDateString()}</td>
        <td>#{if minData.change > 0 then '+' else ''}#{minData.change.toFixed(3)}</td>
        <td>#{minData.y.toFixed(2)}</td>
        <td>#{new Date(minData.x + estFix).toDateString()}</td>
      </tr>"
    
    # console.log new Date(sd.data.filter((d) -> d.change == sd.dataMax)[0].x + estFix).toDateString()

#
buildGraph = (series) =>
  line.color = colors.series[ndx % colors.series.length] for line, ndx in series

  graph = new Highcharts.StockChart
    chart:
      renderTo: 'price-graph'
      events:
        redraw: buildExtremesTable
    rangeSelector:
      inputEnabled: true
      selected: 4
    yAxis:
      labels:
        formatter: () -> "#{@.value}%"
      plotLines: [ { value: 0, width: 2, color: '#444' } ]
    plotOptions:
      series:
        compare: 'percent'
    tooltip:
      pointFormat: '<span style="color:{series.color}">{series.name}</span>: <b>{point.y}<    /b> ({point.change}%)<br/>'
      valueDecimals: 2
    series: series
  buildExtremesTable()

  # Calculate available months, build dropdown
  startDate = new Date(graph.xAxis[0].dataMin)
  month     = startDate.getMonth() + 1
  year      = startDate.getFullYear()
  endDate   = new Date(graph.xAxis[0].dataMax)
  $('#month-select').html ''

  while new Date(year, month) < endDate
    $('#month-select').append "<option data-month='#{month}' data-year='#{year}'>#{months[month]}, #{year}</option>"
    year++ if month == 11
    month = if month == 11 then 0 else month + 1
  
  # Respond to month dropdown changing
  $('#month-select').change (evt) ->
    month = $('#month-select :selected').data 'month'
    year  = $('#month-select :selected').data 'year'
    return unless month? and year?

    start = new Date(parseInt(year), parseInt(month), 1)
    end   = new Date(parseInt(year), parseInt(month)+1, 1)
    graph.xAxis[0].setExtremes(start.getTime(), end.getTime())

#
$ () ->

  #
  initialSector = window.location.pathname.split('/')[2]
  setStyles()

  # Load list of sectors
  $.getJSON '/sector_map.json', (sectorMap) ->
    for sector in (sub for sub, parent of sectorMap).sort()
      $('#sector-select').append "<option>#{sector}</option>"
    $('#sector-select').val decodeURIComponent(initialSector)

    # Respond to sector multi select
    $('#sector-select').change (evt) ->
      val = $(@).val()
      loadPriceData val.map((v) -> encodeURIComponent(v)) if val?

  # Load initial sector price data
  loadPriceData [ initialSector ]
