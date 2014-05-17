throw new Error('HUBOT_DOGECOIND_USER missing') unless process.env.HUBOT_DOGECOIND_USER?
throw new Error('HUBOT_DOGECOIND_PASS missing') unless process.env.HUBOT_DOGECOIND_PASS?

dogecoindConfig =
  user: process.env.HUBOT_DOGECOIND_USER
  pass: process.env.HUBOT_DOGECOIND_PASS
  host: process.env.HUBOT_DOGECOIND_HOST || 'localhost'
  port: process.env.HUBOT_DOGECOIND_PORT || 22555

dogecoind = require('node-dogecoin')(dogecoindConfig)

class Dogebot

  constructor: (@robot) ->
    @slug = @robot.name.replace(/[^a-zA-Z0-9 -]/g, '').replace(/\W+/g, '-')

  getAddress: (user, cb) ->
    dogecoind.exec 'getaccountaddress', @slugForUser(user), (err, result) =>
      @robot.logger.error(err) if err?
      @robot.emit 'dogecoin.getAddress', { user: user, address: result }
      cb?(err, result)

  getBalance: (user, cb) ->
    dogecoind.exec 'getbalance', @slugForUser(user), (err, result) =>
      @robot.logger.error(err) if err?
      result = parseInt(result) || 0 if result?
      @robot.emit 'dogecoin.getBalance', { user: user, balance: result }
      cb?(err, result)

  move: (sender, recipient, amount, cb) ->
    senderSlug    = @slugForUser(sender)
    recipientSlug = @slugForUser(recipient)
    amount        = parseInt(amount)

    @getBalance sender, (err, balance) =>
      if balance >= amount
        dogecoind.exec 'move', senderSlug, recipientSlug, amount, (err, result) =>
          @robot.logger.error(err) if err?
          @robot.emit 'dogecoin.move', {
            sender:    sender
            recipient: recipient
            amount:    amount
          }
          cb?(err, result)
      else
        error = "available balance is #{balance}"
        cb?(error, false)

  sendFrom: (user, address, amount, cb) ->
    if address[0] != 'D' || address.length != 34
      error = "'#{address}' does not appear to be a valid Dogecoin address"
      return cb(error, false)

    @getBalance user, (err, balance) =>
      amount = balance if amount is 'all'
      amount = parseInt(amount)
      if balance >= amount
        userSlug = @slugForUser(user)
        dogecoind.exec 'sendFrom', userSlug, address, amount, (err, result) =>
          @robot.logger.error(err) if err?
          @robot.emit 'dogecoin.sendFrom', {
            user:    user
            address: address
            amount:  amount
            txid:    result
          }
          cb?(err, result)
      else
        error = "available balance is #{balance}"
        cb?(error, false)

  # Helpers

  findUserByMention: (mentionName) ->
    for id, userData of @robot.brain.users()
      return userData if userData.mention_name == mentionName
    return null

  slugForUser: (user) ->
    return "#{@slug}-#{user.id}"

  userFromMsg: (msg) ->
    return @robot.brain.users()[msg.envelope.user.id]

module.exports = Dogebot
