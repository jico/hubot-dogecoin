# Description:
#   Tip with dogecoin
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   <user> +<n> doge - send user n dogecoin
#   hubot register doge - get your dogecoin address
#   hubot such address - alias to register doge
#   hubot much balance - get your dogecoin balance
#   hubot send <n|all> doge to <addr> - withdraw n or all doge to dogecoin address addr
#

{ EventEmitter } = require('events')
http             = require('http')
dogecoin = require('node-dogecoin')({
  user: 'dogecoinrpc'
  pass: '8LD5C7xpSiYvnnNLpxaoCG7nPp8UmBG8UziA9BhbE5ky'
})

class Dogebot extends EventEmitter

  constructor: (@robot) ->
    @robot.brain.on 'loaded', =>
      if @robot.brain.data.doge
        console.log 'redis brain loaded'


module.exports = (robot) ->
  dogebot = new Dogebot(robot)

  robot.hear /((such|much|so|very|doge(coin)?) address|doge register)/i, (msg) ->
    user = robot.brain.users()[msg.envelope.user.id]
    dogecoin.exec 'getaccountaddress', "hubot-test-#{user.id}", (err, address) ->
      msg.reply "your Dogecoin address is #{address}"

  # robot.respond /(such|much|so|very|doge(coin)?) balance/, (msg) ->

  # robot.hear /@(\S+).*(?:tip |\+)(\d+).*doge/, (msg) ->

  # robot.respond /send (\d+|all) ?doge (?:to )?(D\S+)/, (msg) ->
