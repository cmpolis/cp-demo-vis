#
# Chris Polis, 2014

#
initTreeMap = (error, weights, sectorMap) ->
  return if error?

  #
  colors   = "#BED8B3 #D0C6E7 #E5B56E #EDB09B #90E0DB #D5D677
              #B2E196 #E5B2C2 #CED4CF #99CDE2 #8EDEB8 #DBCD9C".split ' '
  width     = Math.min($('.container').width(), 1200)
  height    = $('#treemap').height()
  duration  = 400
  dateNdx   = 0
  running   = false
  playInt   = null
  dateMap   = weights.filter((d) -> d.SubSector == "CHEMICALS")
                     .map((d) -> d.Date)
                     .sort(d3.ascending)

  # Map sectors to tree structure, colors
  sectorTree =  { name: 'sectors', children: [] }
  for name, ndx in $.unique (parent for sub, parent of sectorMap)
    subSectors =  (sub for sub, parent of sectorMap).filter((s) -> sectorMap[s] == name)
    subSectors = subSectors.map (sub) ->
      name: sub
      color: colors[ndx]
      weights: weights.filter (w) -> w.SubSector == sub
    sectorTree.children.push
      name: name
      color: colors[ndx]
      children: subSectors

  # 
  root = d3.select('#treemap')
             .append('div')
               .style 'position', 'relative'
               .style 'width', width
               .style 'height', height
  layout = d3.layout.treemap()
                      .size( [width, height] )
                      .sticky(true)
                      .value((d) -> if d.weights then d.weights[0].Weight else null)
  position = () ->
    @.style "left",   (d) -> "#{d.x}px"
     .style "top",    (d) -> "#{d.y}px"
     .style "width",  (d) -> "#{Math.max(0, d.dx - 1)}px"
     .style "height", (d) -> "#{Math.max(0, d.dy - 1)}px"
  highlightSector = (datum, sel) ->
    d3.selectAll('.sector-cell').style 'opacity', '0.72'
    d3.select('.sector-name').text "#{datum.parent.name} > #{datum.name}"
    d3.select(sel).style 'opacity', '1'

  # Build each node with weight data
  nodes = root.datum(sectorTree).selectAll(".sector-cell")
                .data(layout.nodes).enter()
                  .append 'div'
                    .attr  'class', 'sector-cell'
                    .style 'background', (d) -> d.color
                    .text  (d) -> if d.weights then d.name else ''
                    .on    'mouseover', (d) -> highlightSector(d, @)
                    .on    'click',  (d) ->
                      window.open "/sector/#{encodeURIComponent(d.name)}",
                                  '_blank',
                                  'toolbar=0,location=0,menubar=0'
                    .call  position

  # Quick slider for changing date
  updateDate = (evt, val) =>
    dateNdx = Math.round(val)
    d3.select('.date-label').text (new Date(dateMap[dateNdx])).toDateString()
    valF = (d) -> if d.weights and d.weights[dateNdx] then d.weights[dateNdx].Weight else null
    nodes.data(layout.value(valF).nodes)
      .call(position)
      .text((d) -> if d.value > 0 and d.weights then d.name else '')
  slider =  d3.slider()
               .min(0)
               .max(dateMap.length-1)
               .axis(
                 d3.svg.axis()
                   .tickValues [0, Math.floor(dateMap.length / 2), dateMap.length-1]
                   .tickFormat (d) -> (new Date(dateMap[d])).toDateString()
               ).on('slide', (e, v) -> pause(); updateDate(e, v))
  d3.select('#date-slider').call(slider)
  updateDate(null, 0)

  # Handle play/puase button
  running = false
  step = () =>
    if dateNdx >= (dateMap.length - 2)
      clearInterval(playInt)
      running = false
    running = true
    slider.update(dateNdx)
    updateDate(null, ++dateNdx)
  pause = () =>
    clearInterval(playInt)
    running = false
    d3.select('.play-pause').text 'Play'

  # 
  d3.select('.play-pause').on 'click', () =>
    if running
      pause()
    else
      playInt = setInterval(step, 90)
      d3.select('.play-pause').text 'Pause'

#
$ () ->
  queue().defer(d3.json, '/weights.json')
         .defer(d3.json, '/sector_map.json')
         .await(initTreeMap)
