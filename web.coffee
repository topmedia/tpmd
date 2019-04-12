express = require 'express'
logfmt = require 'logfmt'
formidable = require 'formidable'

config =
  autotask_base: 'https://ww18.autotask.net/Autotask/AutotaskExtend/ExecuteCommand.aspx?'
  short_url: 'http://tpmd.co/at/'

Slack = require 'node-slack'
slack = new Slack 'topmedia', process.env.SLACK_TOKEN

sanitize_quotes = (string) ->
  string.replace /: ""(.+)"",/g, ": \"$1\","

app = express()
app.use logfmt.requestLogger()
app.set 'views', './views'
app.set 'view engine', 'jade'
app.use express.static('public')

app.get '/largetype/:number', (req, res) ->
  res.render 'largetype', message: req.params.number

app.get '/at/:code/:argument/:value', (req, res) ->
  res.redirect "#{config.autotask_base}Code=#{req.params.code}&#{req.params.argument}=#{req.params.value}"

app.post '/notify/new_ticket', (req, res) ->
  form = new formidable.IncomingForm()
  form.parse req, (err, fields, files) ->
    try
      ticket = JSON.parse sanitize_quotes fields.plain
      slack.send
        text: """
          :ticket: *Neues Ticket:* #{ticket.title}
          :office: *Kunde:* #{ticket.account}
          :flags: *Priorität:* #{ticket.priority}
          :inbox_tray: *Queue:* #{ticket.queue}
          #{config.short_url}OpenTicketDetail/TicketNumber/#{ticket.ticket_no}
          #{('@1stlevel' if ticket.priority == 'Kritisch') || ''}
          """
        channel: process.env.SLACK_CHANNEL || '#test'
        username: process.env.SLACK_USERNAME || 'autotask'
        link_names: 1
    catch e
      console.log e
      console.log fields.plain

    res.sendStatus 200

app.post '/notify/new_sales', (req, res) ->
  form = new formidable.IncomingForm()
  form.parse req, (err, fields, files) ->
    try
      ticket = JSON.parse sanitize_quotes fields.plain
      slack.send
        text: """
          :ticket: *Neues Ticket:* #{ticket.title}
          :office: *Kunde:* #{ticket.account}
          #{config.short_url}OpenTicketDetail/TicketNumber/#{ticket.ticket_no}
          """
        channel: process.env.SLACK_CHANNEL_SALES || '#vertrieb'
        username: process.env.SLACK_USERNAME || 'autotask'

    res.sendStatus 200

app.post '/notify/new_alarm', (req, res) ->
  form = new formidable.IncomingForm()
  form.parse req, (err, fields, files) ->
    try
      ticket = JSON.parse sanitize_quotes fields.plain
      success = slack.send
        text: """
          :ticket: *Neuer Alarm:* #{ticket.title}
          :office: *Kunde:* #{ticket.account}
          #{config.short_url}OpenTicketDetail/TicketNumber/#{ticket.ticket_no}
          """
        channel: process.env.SLACK_CHANNEL_AEM || process.env.SLACK_CHANNEL || process.env.SLACK_CHANNEL || '#test'
        username: process.env.SLACK_USERNAME || 'autotask'
    catch e
      console.log e
      console.log fields.plain

    console.log success
    res.sendStatus 200

app.post '/notify/closed_ticket', (req, res) ->
  form = new formidable.IncomingForm()
  form.parse req, (err, fields, files) ->
    try
      ticket = JSON.parse sanitize_quotes fields.plain
      slack.send
        text: """
          :green_heart: *Ticket abgeschlossen:* #{ticket.title}
          :office: *Kunde:* #{ticket.account}
          :boy: *Von:* #{ticket.assignee}
          #{config.short_url}OpenTicketDetail/TicketNumber/#{ticket.ticket_no}
          """
        channel: process.env.SLACK_CHANNEL || '#test'
        username: process.env.SLACK_USERNAME || 'autotask'

    res.sendStatus 200

app.post '/notify/closed_alarm', (req, res) ->
  form = new formidable.IncomingForm()
  form.parse req, (err, fields, files) ->
    try
      ticket = JSON.parse sanitize_quotes fields.plain
      slack.send
        text: """
          :green_heart: *Alarm geschlossen:* #{ticket.title}
          :office: *Kunde:* #{ticket.account}
          #{config.short_url}OpenTicketDetail/TicketNumber/#{ticket.ticket_no}
          """
        channel: process.env.SLACK_CHANNEL_AEM || '#test'
        username: process.env.SLACK_USERNAME || 'autotask'

    res.sendStatus 200

app.post '/notify/ticket_assigned', (req, res) ->
  form = new formidable.IncomingForm()
  form.parse req, (err, fields, files) ->
    try
      ticket = JSON.parse sanitize_quotes fields.plain
      slack.send
        text: """
          :hammer: *Ticket zugewiesen:* #{ticket.title}
          :office: *Kunde:* #{ticket.account}
          :boy: *An:* #{ticket.assignee}
          #{config.short_url}OpenTicketDetail/TicketNumber/#{ticket.ticket_no}
          """
        channel: process.env.SLACK_CHANNEL || '#test'
        username: process.env.SLACK_USERNAME || 'autotask'

    res.sendStatus 200

app.post '/notify/ticket_escalated', (req, res) ->
  form = new formidable.IncomingForm()
  form.parse req, (err, fields, files) ->
    try
      ticket = JSON.parse sanitize_quotes fields.plain
      slack.send
        text: """
          :bomb: *Ticket an #{ticket.queue} eskaliert:* #{ticket.title}
          :office: *Kunde:* #{ticket.account}
          #{config.short_url}OpenTicketDetail/TicketNumber/#{ticket.ticket_no}
          """
        channel: process.env.SLACK_CHANNEL || '#test'
        username: process.env.SLACK_USERNAME || 'autotask'

    res.sendStatus 200

port = Number process.env.PORT || 5000
app.listen port, ->
  console.log "Listening on #{port}"
