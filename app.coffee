###
Module dependencies.
###
config = require("./config")
express = require("express")
lessMiddleware = require('less-middleware')
path = require("path")
http = require("http")
socketIo = require("socket.io")
exec = require('child_process').exec
path = require('path')
fs = require 'fs'

#passport.use "email", new LocalStrategy(
  #usernameField: "email"
#, (email, password, done) ->
  #process.nextTick ->
    #User.authEmail email, password, done
#)

#passport.serializeUser (user, done) ->
  #done null, user.id

#passport.deserializeUser (id, done) ->
  #User.findById id, (err, user) ->
    #done err, user

# connect the database
#mongoose.connect config.mongodb

# create app, server, and web sockets
app = express()
server = http.createServer(app)
io = socketIo.listen(server)

# Make socket.io a little quieter
io.set "log level", 1

# Give socket.io access to the passport user from Express
#io.set('authorization', passportSocketIo.authorize(
  #sessionKey: 'connect.sid',
  #sessionStore: sessionStore,
  #sessionSecret: config.sessionSecret,
  #fail: (data, accept) ->
  #keeps socket.io from bombing when user isn't logged in
    #accept(null, true);
#));
app.configure ->
  bootstrapPath = path.join(__dirname, 'assets','css', 'bootstrap')
  app.set "port", process.env.PORT or 3000
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  
  # use the connect assets middleware for Snockets sugar
  app.use require("connect-assets")()
  app.use express.favicon()
  app.use express.logger(config.loggerFormat)
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser(config.sessionSecret)
  app.use express.session(secret: "shhhh")
  #app.use passport.initialize()
  #app.use passport.session()
  app.use app.router
  app.use lessMiddleware
        src: path.join(__dirname,'assets','css')
        paths  : bootstrapPath
        dest: path.join(__dirname,'public','css')
        prefix: '/css'
        compress: true
  app.use express.static(path.join(__dirname,"public"))
  app.use express.errorHandler()  if config.useErrorHandler

io.sockets.on "connection",  (socket) ->

  socket?.emit "connection", "I am your father"

  socket.on "disconnect", ->
    console.log "disconnected"

  socket.on "delete", (name)->
    fs.unlink "./csvs/#{name}", (err) ->
      if err
        console.log "err deleting: #{err}"
      else
        socket.emit "deleted", name


#
# UI routes
app.get "/", (req, res) ->
  fs.readdir './csvs/', (err, files)->
    res.render "index.jade",
      title: "Production Grapher"
      csvs: files


app.post "/", (req, res) ->
  if req.files && req.files.csv.size > 0
    fs.readFile req.files.csv.path, (err, data) ->
      fs.writeFile "./csvs/#{req.files.csv.name}", data, (err) ->
        res.redirect('/')
    
app.get "/data.csv", (req, res) ->
  fs.readFile './csvs/data.csv', (err, data)->
    return res.send(data)

app.get "/csv/:name", (req, res) ->
  fs.readFile "./csvs/#{req.params.name}", (err, data)->
    return res.send(data)


#child = exec 'python ../pi/pi.py', (error, stdout, stderr)-> 
    #console.log('stdout: ' + stdout);
    #console.log('stderr: ' + stderr);
    #if error != null
      #console.log('exec error: ' + error);

server.listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")

