class Dogebot

  constructor: (@robot) ->
    @slug = @robot.name.replace(/[^a-zA-Z0-9 -]/g, '').replace(/\W+/g, '-')

  findUserByMention: (mentionName) ->
    for id, userData of @robot.brain.users()
      return userData if userData.mention_name == mentionName
    return null

  slugForUser: (user) ->
    return "#{@slug}-#{user.id}"

  userFromMsg: (msg) ->
    return @robot.brain.users()[msg.envelope.user.id]

module.exports = Dogebot
