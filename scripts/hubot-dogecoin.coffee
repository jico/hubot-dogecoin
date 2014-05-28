# Description:
#   wow! tip with dogecoin
#
# Dependencies:
#   "node-dogecoin": "~0.3.5"
#
# Configuration:
#   HUBOT_DOGECOIND_USER
#   HUBOT_DOGECOIND_PASS
#   HUBOT_DOGECOIND_HOST (optional)
#   HUBOT_DOGECOIND_PORT (optional)
#
# Commands:
#   <user> +<n> doge - tip user n dogecoin
#   doge register - get your dogecoin address
#   doge address  - get your dogecoin address
#   doge balance  - get your dogecoin balance
#   send <n|all> doge to <addr> - withdraw n or all doge to dogecoin address addr
#
# Notes:
#   Must have a dogecoind instance running. Also uses Hubot brain. "doge"
#   trigger keyword has the following aliases: such, much, so, very, dogecoin.
#
# Author:
#   Jico Baligod <jico@baligod.com>
#

Dogebot = require('./dogebot')

module.exports = (robot) ->
  dogebot = new Dogebot(robot)
  unknownErrMsg = 'woops, something went wrong :('

  robot.hear /((such|much|so|very|doge(coin)?) address|doge register)/i, (msg) ->
    user = dogebot.userFromMsg(msg)
    dogebot.getAddress user, (err, address) ->
      if err?
        msg.reply unknownErrMsg
      else
        msg.reply "your Dogecoin address is #{address}"

  robot.hear /(such|much|so|very|doge(coin)?) balance|doge balance/, (msg) ->
    user = dogebot.userFromMsg(msg)
    dogebot.getBalance user, (err, balance) ->
      if err?
        msg.reply unknownErrMsg
      else
        usdBalance = dogebot.dogeToUsd(balance)
        msg.reply "your Dogecoin balance is #{balance} ($#{usdBalance})"

  robot.hear /@(\S+).*(?:tip |\+)(\d+).*doge/, (msg) ->
    recipientNick = msg.match[1]
    amount        = parseInt(msg.match[2])
    sender        = dogebot.userFromMsg(msg)
    recipient     = dogebot.findUserByMention(recipientNick)

    if recipient?
      dogebot.move sender, recipient, amount, (err, success) ->
        if success
          msg.send "@#{recipient.mention_name} +#{amount} doge from @#{sender.mention_name}"
        else
          if err?
            msg.reply err
          else
            msg.reply unknownErrMsg
    else
      msg.send "Couldn't find #{recipientNick}"

  robot.hear /send (\d+|all) ?doge (?:to )?(D\S+)/, (msg) ->
    user    = dogebot.userFromMsg(msg)
    amount  = msg.match[1].toLowerCase()
    address = msg.match[2]

    dogebot.sendFrom user, address, amount, (err, txid) ->
      if txid
        message = """
          \n#{parseInt(amount)} doge sent to #{address}
          Transaction: http://dogechain.info/tx/#{txid}
        """
        msg.reply message
      else
        if err?
          msg.reply err
        else
          msg.reply unknownErrMsg

