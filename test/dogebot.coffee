expect  = require('expect.js')
Dogebot = require('../scripts/dogebot')

describe 'Dogebot', ->
  beforeEach (done) ->
    @robot =
      name: 'robot'
      brain:
        users: -> {}
    done()

  describe 'instance variables', ->
    it 'sets a slug for itself', (done) ->
      @robot.name = 'Doge bot!'
      dogebot = new Dogebot(@robot)
      expect(dogebot.slug).to.be('Doge-bot')
      done()

  describe 'findUserByMention', ->
    beforeEach (done) ->
      @robot.brain.users = ->
        return users =
          123:
            id: 123
            mention_name: 'shibe'
      done()

    it 'returns null if user is not found', (done) ->
      dogebot = new Dogebot(@robot)
      user = dogebot.findUserByMention('notreal')
      expect(user).to.be(null)
      done()

    it 'returns the user object matching the mention name', (done) ->
      dogebot = new Dogebot(@robot)
      user = dogebot.findUserByMention('shibe')
      expect(user).to.eql(@robot.brain.users()['123'])
      done()

  describe 'slugForUser', ->
    it 'returns a user slug', (done) ->
      dogebot = new Dogebot(@robot)
      user = { id: 123 }
      slug = dogebot.slugForUser(user)
      expect(slug).to.be("#{dogebot.slug}-#{user.id}")
      done()

  describe 'userFromMsg', ->
    it 'returns a user object from a message', (done) ->
      user = { id: 123 }
      msg =
        envelope:
          user: user
      @robot.brain.users = -> { 123: user }
      dogebot = new Dogebot(@robot)
      expect(dogebot.userFromMsg(msg)).to.eql(user)
      done()
