#= require jquery
#= require underscore
# =require backbone
#= require bootstrapManifest
# =require socket.io
# =require helpers

@a = @a || {}

slugify = (value) ->
  value.toLowerCase().replace(/-+/g, "").replace(/\s+/g, "-").replace /[^a-z0-9-]/g, ""

getGraph = ->
  try
    margin =
      top: 20
      right: 20
      bottom: 30
      left: 70
    
    width = 960 - margin.left - margin.right
    height = 500 - margin.top - margin.bottom
    x = d3.scale.linear().range([0, width])
    y = d3.scale.linear().range([height, 0])
    xAxis = d3.svg.axis().scale(x).orient("bottom")
    yAxis = d3.svg.axis().scale(y).orient("left")
    color = d3.scale.category10()
    line = d3.svg.line()
      .interpolate("basis")
      .x((d) ->
        #if d.val && d.val > 0
          x d.month
      ).y((d) ->
        #if d.val && d.val > 0
          y d.val
      )

    min = (d) ->
      d3.min Object.keys(d), (v) ->
        if d[v]
          slug = slugify v
          if $("##{slug}-toggle input").length > 0
            if !$("##{slug}-toggle input")[0].checked
              return 100000
          val = parseInt d[v].replace(",","")
          if val > 50
            return val
          else
            return 1000000
    max = (d) ->
      d3.max Object.keys(d), (v) ->
        if d[v]
          slug = slugify v
          if $("##{slug}-toggle input").length > 0
            if !$("##{slug}-toggle input")[0].checked
              return -100000
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

    average = d3.svg.line()
      .interpolate("basis")
      .x((d) ->
        x d.index
      ).y((d) ->
        d3.mean d.values, (b)->
          b.val
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

      svg.append("path")
        .datum(wells)
        .attr("class", "line")
        .attr("id", "average")
        .attr("fill", "#f00")
        .attr("d", average)
      
      well = svg.selectAll(".well")
        .data(wells)
        .enter()
        .append("g")
        .attr("class", "well")

      well.append("path")
        .attr("class", "line")
        .attr('id', (d) ->
          slugify d.name
        )
        .attr("d", (d) ->
          line d.values
        )
        .style("stroke", (d) ->
          color d.name
        )

      for el in wells
        slug = slugify el.name
        html = "<div title='#{el.name}' id='#{slug}-toggle' class='span2 well-toggle'>"
        html += "<input class='inline' type='checkbox' name='#{slug}' checked/>"
        color = $("##{slug}").css("stroke")
        name = el.name
        max_len = 12
        if name.length > max_len
          name = name.substring(0,max_len) + "..."
        html += "<label class='inline' style='margin-left: 5px; color:#{color};'>#{name}</label>"
        html += "</div>"
        $("#canvas").append(html)
        $("##{slug}-toggle").click (el) ->
          line = $("#"+$(@).attr('id').replace("-toggle",""))
          if el.target.tagName == 'LABEL'
            @.children[0].checked = !@.children[0].checked
          if @.children[0].checked
            line.show(400)
          else
            line.hide(400)
          $(".area").remove()
          svg.append("path")
            .datum(data)
            .attr("class", "area")
            .attr("fill", $(".area").css("fill"))
            .attr("d", area)

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
    #console.log $(@).val()
    $("#download-csv").attr "href","/csv/#{$('#data-set').val()}"
    getGraph()
    true

  $("#delete-csv").click ->
    socket.emit "delete", $("#data-set").val()

  $("#download-csv").attr "href","/csv/#{$('#data-set').val()}"

  getGraph()
