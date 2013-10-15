#= require jquery
#= require underscore
# =require backbone
#= require bootstrapManifest
# =require socket.io
# =require helpers

@a = @a || {}

getGraph = ->
  try
    margin =
      top: 20
      right: 20
      bottom: 150
      left: 70
    
    width = 960 - margin.left - margin.right
    height = 550 - margin.top - margin.bottom
    x = d3.scale.linear().range([0, width])
    y = d3.scale.linear().range([height, 0])
    xAxis = d3.svg.axis().scale(x).orient("bottom")
    yAxis = d3.svg.axis().scale(y).orient("left")
    color = d3.scale.category10()
    line = d3.svg.line()
      .interpolate("basis")
      .x((d) ->
        #if typeof(d.month) == "number"
          x d.month
      ).y((d) ->
        #if typeof(d.val) == "number"
          y d.val
      )

    min = (d) ->
      d3.min Object.keys(d), (v) ->
        if d[v]
          val = parseInt d[v].replace(",","")
          if val > 50
            return val
          else
          return 1000000
    max = (d) ->
      d3.max Object.keys(d), (v) ->
        if d[v]
          val = parseInt d[v].replace(",","")
          val
        else
          return -100000
    area = d3.svg.area()
      .interpolate("basis")
      .x( (d) ->
        x(d['Month']-1)
      ).y0( (d) ->
        y(min(d))
      ).y1( (d) ->
        y(max(d))
      )

    if $("#canvas").children().length > 0
      $("#canvas").html("")

    svg = d3.select("#canvas")
      .append("svg")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
      .append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")")

    svg.on 'error', ->
      $("#canvas").html("<h2>error rendering data set. try another</h2>")
    d3.csv "/csv/#{$("#data-set").val()}", (err, data) ->
      keys = Object.keys(data[0])
      locs = []
      console.log locs
      for loc in keys
        if typeof(loc) == 'string'
          if loc != 'Month'
            if loc.length > 2
              locs.push loc
      datz = []
      units = ""
      for i of data
        if parseInt(i) == 0 && units.length < 2
          units = data[i][locs[0]]
        else if data[i][locs[0]] && data[i][locs[0]].length > 1
          datz.push data[i]

      data = datz
      @a.data = data
      
      color.domain d3.keys(data[0]).filter((key) ->
        key isnt "Month"
      )

      c = 0
      @a.wells = wells = color.domain().map((name) ->
        name: name
        index: c++
        values: data.map((d) ->
          if d[name]
            val = parseFloat(d[name].replace(",",""))
            if !val
              val = 0
            return {
              month: data.indexOf(d)
              val: val
            }
          else
            return {
              month: data.indexOf(d)
              val: 0
            }
        )
      )

      x.domain d3.extent(data, (d) ->
        data.indexOf(d)
      )
      #x.domain([0,36])

      y.domain [d3.min(wells, (c) ->
        d3.min c.values, (v) ->
          v.val
      ), d3.max(wells, (c) ->
        d3.max c.values, (v) ->
          v.val
      )]

      svg.append("path")
        .datum(data)
        .attr("class", "area")
        .attr("fill", $(".area").css("fill"))
        .attr("d", area)
      
      well = svg.selectAll(".well")
        .data(wells)
        .enter()
        .append("g")
        .attr("class", "well")

      well.append("path")
        .attr("class", "line")
        .attr("d", (d) ->
          line d.values
        )
        .style("stroke", (d) ->
          color d.name
        )

      well.append("text").datum((d) ->
        name: d.name
        index: d.index
        ).attr("transform", (d) ->
          "translate(" + parseInt( 20 + ( d.index % 4 ) * 210 ) +
          "," +
          parseInt(height + 40 + ( Math.floor( d.index / 4 ) ) * 20 ) +
          ")"
        ).attr("x", 3).attr("dy", ".35em").text (d) ->
          d.name.substr(0,20)
        .style("fill", (d) ->
          color d.name
        )
      
      svg.append("g")
        .attr("class", "x axis path")
        .attr("transform", "translate(0," + height + ")")
        .call xAxis

      svg.append("g")
        .attr("class", "y axis")
        .call(yAxis)
        .append("text")
        .attr("transform", "rotate(-90)")
        .attr("y", 6)
        .attr("dy", ".71em")
        .style("text-anchor", "end")
        .text units

      svg.append("text")
          .attr("x", (width / 2))             
          .attr("y", 0 - (margin.top / 2))
          .attr("text-anchor", "middle")  
          .style("font-size", "16px") 
          .style("font-variant", "small-caps")  
          .text($("#data-set").val()?.toLowerCase())
  catch err
    $("#canvas").html("<h2>error rendering data set. try another</h2>")

window.onerror = ->
  $("#canvas").html("<h2>error rendering data set. try another</h2>")

$(window).ready ->
  # set up the socket.io and OSC
  socket = io.connect() 
  a.socket = socket

  socket.on "connection", (msg) ->
    console.log "connected"
    socket.emit "hello", "world"

  socket.on "deleted", (name) ->
    $("option[name='#{name}']").remove()
    $('#data-set').trigger 'change'

  $("#data-set").change ->
    console.log $(@).val()
    getGraph()
    true

  $("#delete-csv").click ->
    socket.emit "delete", $("#data-set").val()

  getGraph()
