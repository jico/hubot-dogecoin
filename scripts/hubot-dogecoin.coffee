# Description:
#   wow! tip with dogecoin
#
# Dependencies:
#   node-dogecoin
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

throw new Error('HUBOT_DOGECOIND_USER missing') unless process.env.HUBOT_DOGECOIND_USER?
throw new Error('HUBOT_DOGECOIND_PASS missing') unless process.env.HUBOT_DOGECOIND_PASS?

dogecoindConfig =
  user: process.env.HUBOT_DOGECOIND_USER
  pass: process.env.HUBOT_DOGECOIND_PASS
  host: process.env.HUBOT_DOGECOIND_HOST || 'localhost'
  port: process.env.HUBOT_DOGECOIND_PORT || 22555

dogecoin = require('node-dogecoin')(dogecoindConfig)
Dogebot  = require('./dogebot')

module.exports = (robot) ->
  dogebot = new Dogebot(robot)

  robot.hear /((such|much|so|very|doge(coin)?) address|doge register)/i, (msg) ->
    user = dogebot.userFromMsg(msg)
    dogecoin.exec 'getaccountaddress', dogebot.slugForUser(user), (err, address) ->
      msg.reply "your Dogecoin address is #{address}"

  robot.hear /(such|much|so|very|doge(coin)?) balance|doge balance/, (msg) ->
    user = dogebot.userFromMsg(msg)
    dogecoin.exec 'getbalance', dogebot.slugForUser(user), (err, balance) ->
      balance = parseInt(balance) || 0
      msg.reply "your Dogecoin balance is #{balance}"

  robot.hear /@(\S+).*(?:tip |\+)(\d+).*doge/, (msg) ->
    recipientMentionName = msg.match[1]
    amount = parseInt(msg.match[2])
    sender = dogebot.userFromMsg(msg)
    recipient = dogebot.findUserByMention(recipientMentionName)

    if recipient?
      senderSlug = dogebot.slugForUser(sender)
      recipientSlug = dogebot.slugForUser(recipient)

      dogecoin.exec 'getbalance', senderSlug, (err, balance) ->
        balance = parseInt(balance) || 0
        if balance >= amount
          dogecoin.exec 'move', senderSlug, recipientSlug, amount, (err, success) ->
            if err?
              msg.reply "Woops, something went wrong :("
              console.log err
            if success
              msg.send "@#{recipient.mention_name} +#{amount} doge from @#{sender.mention_name}"
        else
          msg.reply "you only have #{balance} doge!"
    else
      msg.send "Couldn't find #{recipientMentionName}"

  robot.hear /send (\d+|all) ?doge (?:to )?(D\S+)/, (msg) ->
    user           = dogebot.userFromMsg(msg)
    withdrawAmount = msg.match[1].toLowerCase()
    toAddress      = msg.match[2]

    # Validate deposit address
    if toAddress[0] != 'D' || toAddress.length != 34
      return msg.reply "that doesn't seem to be a valid Dogecoin address"

    dogecoin.exec 'getbalance', dogebot.slugForUser(user), (err, balance) ->
      balance = parseInt(balance) || 0
      return msg.reply "you have no doge in your account" if balance <= 0

      if withdrawAmount is 'all'
        withdrawAmount = balance

      withdrawAmount = parseInt(withdrawAmount)

      if withdrawAmount > balance
        return msg.reply "you only have #{balance} doge!"
      else
        dogecoin.exec 'sendfrom', dogebot.slugForUser(user), toAddress, withdrawAmount, (err, txid) ->
          if err?
            msg.reply "woops, something went wrong :("
            console.log err
          if txid?
            message = """
              \n#{parseInt(withdrawAmount)} doge sent to #{toAddress}
              Balance: #{balance - withdrawAmount} doge
              Transaction: http://dogechain.info/tx/#{txid}
            """
            msg.reply message
