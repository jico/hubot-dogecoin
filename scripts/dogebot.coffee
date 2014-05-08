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

throw new Error('HUBOT_DOGECOIND_USER missing') unless process.env.HUBOT_DOGECOIND_USER?
throw new Error('HUBOT_DOGECOIND_USER missing') unless process.env.HUBOT_DOGECOIND_PASS?

dogecoin = require('node-dogecoin')({
  user: process.env.HUBOT_DOGECOIND_USER
  pass: process.env.HUBOT_DOGECOIND_PASS
})

class Dogebot

  constructor: (@robot) ->
    @robot.slug = @robot.name.replace(/[^a-zA-Z0-9 -]/g, '').replace(/\W+/g, '-')

  slugForUser: (user) ->
    "#{@robot.slug}-#{user.id}"

  userFromMsg: (msg) ->
    return @robot.brain.users()[msg.envelope.user.id]

module.exports = (robot) ->
  dogebot = new Dogebot(robot)

  robot.hear /((such|much|so|very|doge(coin)?) address|doge register)/i, (msg) ->
    user = dogebot.userFromMsg(msg)
    dogecoin.exec 'getaccountaddress', dogebot.slugForUser(user), (err, address) ->
      msg.reply "your Dogecoin address is #{address}"

  robot.hear /(such|much|so|very|doge(coin)?) balance|doge balance/, (msg) ->
    user = dogebot.userFromMsg(msg)
    dogecoin.exec 'getbalance', dogebot.slugForUser(user), (err, balance) ->
      msg.reply "your Dogecoin balance is #{balance.result}"

  # robot.hear /@(\S+).*(?:tip |\+)(\d+).*doge/, (msg) ->

  # robot.respond /send (\d+|all) ?doge (?:to )?(D\S+)/, (msg) ->
