express = require 'express'
logfmt = require 'logfmt'
formidable = require 'formidable'

config =
  autotask_base: 'https://ww7.autotask.net/Autotask/AutotaskExtend/ExecuteCommand.aspx?'
  short_url: 'http://tpmd.co/at/'

Slack = require 'node-slack'
slack = new Slack 'topmedia', process.env.SLACK_TOKEN

app = express()
app.use logfmt.requestLogger()

app.get '/at/:code/:argument/:value', (req, res) ->
  res.redirect "#{config.autotask_base}Code=#{req.params.code}&#{req.params.argument}=#{req.params.value}"

app.post '/notify/new_ticket', (req, res) ->
  form = new formidable.IncomingForm()
  form.parse req, (err, fields, files) ->
    ticket = JSON.parse fields.plain
    slack.send
      text: """
        :ticket:  *New ticket:* #{ticket.title}
        :office:  *Account:* #{ticket.account}
        #{config.short_url}OpenTicketDetail/TicketNumber/#{ticket.ticket_no}
        """
      channel: process.env.SLACK_CHANNEL || '#test'
      username: process.env.SLACK_USERNAME || 'autotask'
    res.send 200

port = Number process.env.PORT || 5000
app.listen port, ->
  console.log "Listening on #{port}"
