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

  findUserByMention: (mentionName) ->
    user = null
    users = @robot.brain.users()
    for id, userData of users
      if userData.mention_name == mentionName
        user = users[id]
    return user

  slugForUser: (user) ->
    return "#{@robot.slug}-#{user.id}"

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
        console.log balance
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

