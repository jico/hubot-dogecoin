process.env.HUBOT_DOGECOIND_USER = 'user'
process.env.HUBOT_DOGECOIND_PASS = 'pass'

rewire       = require('rewire')
expect       = require('expect.js')
sinon        = require('sinon')
EventEmitter = require('events').EventEmitter
Dogebot      = rewire('../scripts/dogebot')

describe 'Dogebot', ->
  beforeEach (done) ->
    @robot = new EventEmitter
    @robot.name = 'robot'
    @robot.brain =
      users: -> {}
    @robot.logger =
      error: sinon.stub()
    done()

  describe 'instance variables', ->
    it 'sets a slug for itself', (done) ->
      @robot.name = 'Doge bot!'
      dogebot = new Dogebot(@robot)
      expect(dogebot.slug).to.be('Doge-bot')
      done()

  describe '#findUserByMention', ->
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

  describe '#slugForUser', ->
    it 'returns a user slug', (done) ->
      dogebot = new Dogebot(@robot)
      user = { id: 123 }
      slug = dogebot.slugForUser(user)
      expect(slug).to.be("#{dogebot.slug}-#{user.id}")
      done()

  describe '#userFromMsg', ->
    it 'returns a user object from a message', (done) ->
      user = { id: 123 }
      msg =
        envelope:
          user: user
      @robot.brain.users = -> { 123: user }
      dogebot = new Dogebot(@robot)
      expect(dogebot.userFromMsg(msg)).to.eql(user)
      done()

  describe '#getAddress', ->
    beforeEach (done) ->
      @user = { id: 123 }
      @fakeDogecoinAddress = 'Dabcdefghijklmnopqrstuvwxyz1234567'
      done()

    it 'retrieves the Dogecoin address for a user', (done) ->
      execStub = sinon.stub().yields(null, @fakeDogecoinAddress)

      Dogebot.__set__('dogecoind', { exec: execStub })
      dogebot = new Dogebot(@robot)

      dogebot.getAddress @user, (err, result) =>
        expect(execStub.withArgs('getaccountaddress', dogebot.slugForUser(@user)).calledOnce).to.be(true)
        expect(err).to.be(null)
        expect(result).to.be(@fakeDogecoinAddress)
        done()

    it 'logs any errors', (done) ->
      errorStub = new Error('some error')
      execStub  = sinon.stub().yields(errorStub, null)

      Dogebot.__set__('dogecoind', { exec: execStub })
      dogebot = new Dogebot(@robot)

      dogebot.getAddress @user, (err, result) =>
        expect(err).to.be(errorStub)
        expect(result).to.be(null)
        expect(@robot.logger.error.withArgs(errorStub).calledOnce).to.be(true)
        done()

    it 'emits an event', (done) ->
      execStub = sinon.stub().yields(null, @fakeDogecoinAddress)

      Dogebot.__set__('dogecoind', { exec: execStub })
      dogebot = new Dogebot(@robot)

      @robot.on 'dogecoin.getAddress', (data) =>
        expectedData =
          user:    @user
          address: @fakeDogecoinAddress
        expect(data).to.eql(expectedData)
        done()
      dogebot.getAddress(@user)

  describe '#getBalance', ->
    beforeEach (done) ->
      @execStub     = sinon.stub()
      @user         = { id: 123 }
      Dogebot.__set__('dogecoind', { exec: @execStub })
      @dogebot = new Dogebot(@robot)
      done()

    it 'retrieves the Dogecoin balance for a user', (done) ->
      balance = 100
      @execStub.yields(null, balance)
      @dogebot.getBalance @user, (err, result) =>
        expect(@execStub.withArgs('getbalance', @dogebot.slugForUser(@user)).calledOnce).to.be(true)
        expect(err).to.be(null)
        expect(result).to.be(balance)
        done()

    it 'returns zero for a result other than a positive integer', (done) ->
      balance = { error: 'Some weird error' }
      @execStub.yields(null, balance)
      @dogebot.getBalance @user, (err, result) =>
        expect(@execStub.withArgs('getbalance', @dogebot.slugForUser(@user)).calledOnce).to.be(true)
        expect(err).to.be(null)
        expect(result).to.be(0)
        done()

    it 'logs any errors', (done) ->
      errorStub = new Error('some error')
      @execStub.yields(errorStub, null)
      @dogebot.getBalance @user, (err, result) =>
        expect(err).to.be(errorStub)
        expect(result).to.be(null)
        expect(@robot.logger.error.withArgs(errorStub).calledOnce).to.be(true)
        done()

    it 'emits an event', (done) ->
      balance = 100
      @execStub.yields(null, balance)
      @robot.on 'dogecoin.getBalance', (data) =>
        expectedData =
          user:    @user
          balance: balance
        expect(data).to.eql(expectedData)
        done()
      @dogebot.getBalance(@user)

  describe '#move', ->
    beforeEach (done) ->
      @execStub = sinon.stub()
      d = new Dogebot(@robot)
      @sender        = { id: 123 }
      @recipient     = { id: 456 }
      @senderSlug    = d.slugForUser(@sender)
      @recipientSlug = d.slugForUser(@recipient)
      done()

    it 'moves an amount of dogecoin between two accounts', (done) ->
      amount = '100'
      @execStub.withArgs('getbalance').yields(null, parseInt(amount) + 100)
      @execStub.withArgs('move').yields(null, true)

      Dogebot.__set__('dogecoind', { exec: @execStub })
      dogebot = new Dogebot(@robot)

      dogebot.move @sender, @recipient, amount, (err, result) =>
        expect(@execStub.withArgs('move', @senderSlug, @recipientSlug, parseInt(amount)).calledOnce).to.be(true)
        expect(err).to.be(null)
        expect(result).to.be(true)
        done()

    it 'validates the sender balance', (done) ->
      balance = 100
      amount  = 200

      @execStub.withArgs('getbalance', @senderSlug).yields(null, balance)

      Dogebot.__set__('dogecoind', { exec: @execStub })
      dogebot = new Dogebot(@robot)

      dogebot.move @sender, @recipient, amount, (err, result) ->
        expect(err).to.eql("available balance is #{balance}")
        expect(result).to.be(false)
        done()

    it 'logs any errors', (done) ->
      errorStub = new Error('some error')
      @execStub.withArgs('getbalance').yields(null, 200)
      @execStub.withArgs('move').yields(errorStub, null)

      Dogebot.__set__('dogecoind', { exec: @execStub })
      dogebot = new Dogebot(@robot)

      dogebot.move @sender, @recipient, 100, (err, result) =>
        expect(err).to.be(errorStub)
        expect(result).to.be(null)
        expect(@robot.logger.error.withArgs(errorStub).calledOnce).to.be(true)
        done()

    it 'emits an event', (done) ->
      amount = 100
      @execStub.withArgs('getbalance').yields(null, parseInt(amount) + 100)
      @execStub.withArgs('move').yields(null, true)

      Dogebot.__set__('dogecoind', { exec: @execStub })
      dogebot = new Dogebot(@robot)

      @robot.on 'dogecoin.move', (data) =>
        expectedData =
          sender:    @sender
          recipient: @recipient
          amount:    amount
        done()
      dogebot.move(@sender, @recipient, 100)

  describe '#sendFrom', ->
    beforeEach (done) ->
      d = new Dogebot(@robot)
      @execStub    = sinon.stub()
      @user        = { id: 123 }
      @userSlug    = d.slugForUser(@sender)
      @fakeAddress = 'Dabcdefghijklmnopqrstuvwxyz1234567'
      done()

    it 'validates the receiving address', (done) ->
      invalidAddress = 'NotADogecoinAddress'
      dogebot        = new Dogebot(@robot)
      dogebot.sendFrom @user, invalidAddress, 100, (err, result) ->
        expect(err).to.eql("'#{invalidAddress}' does not appear to be a valid Dogecoin address")
        done()

    it 'validates the sender balance', (done) ->
      balance = 100
      amount  = 200
      @execStub.withArgs('getbalance').yields(null, balance)

      Dogebot.__set__('dogecoind', { exec: @execStub })
      dogebot = new Dogebot(@robot)

      dogebot.sendFrom @user, @fakeAddress, amount, (err, result) ->
        expect(err).to.eql("available balance is #{balance}")
        expect(result).to.be(false)
        done()

    it 'sends Dogecoin from an account to an address', (done) ->
      balance = 500
      amount  = '200'
      txid    = 'abc123'
      @execStub.withArgs('getbalance', @userSlug).yields(null, balance)
      @execStub.withArgs('sendFrom').yields(null, txid)

      Dogebot.__set__('dogecoind', { exec: @execStub })
      dogebot = new Dogebot(@robot)

      dogebot.sendFrom @user, @fakeAddress, amount, (err, result) =>
        expect(@execStub.withArgs('sendFrom', @userSlug, @fakeAddress, parseInt(amount)).calledOnce).to.be(true)
        expect(err).to.be(null)
        expect(result).to.be(txid)
        done()

    it 'recognizes the all amount keyword', (done) ->
      balance = 500
      amount  = 'all'
      txid    = 'abc123'
      @execStub.withArgs('getbalance').yields(null, balance)
      @execStub.withArgs('sendFrom').yields(null, txid)

      Dogebot.__set__('dogecoind', { exec: @execStub })
      dogebot = new Dogebot(@robot)

      dogebot.sendFrom @user, @fakeAddress, amount, (err, result) =>
        expect(@execStub.withArgs('sendFrom', @userSlug, @fakeAddress, balance).calledOnce).to.be(true)
        expect(err).to.be(null)
        expect(result).to.be(txid)
        done()

    it 'logs any errors', (done) ->
      errorStub = new Error('some error')
      @execStub.withArgs('getbalance').yields(null, 200)
      @execStub.withArgs('sendFrom').yields(errorStub, null)

      Dogebot.__set__('dogecoind', { exec: @execStub })
      dogebot = new Dogebot(@robot)

      dogebot.sendFrom @user, @fakeAddress, 100, (err, result) =>
        expect(err).to.be(errorStub)
        expect(result).to.be(null)
        expect(@robot.logger.error.withArgs(errorStub).calledOnce).to.be(true)
        done()

    it 'emits an event', (done) ->
      balance = 500
      amount  = '200'
      txid    = 'abc123'
      @execStub.withArgs('getbalance').yields(null, balance)
      @execStub.withArgs('sendFrom').yields(null, txid)

      Dogebot.__set__('dogecoind', { exec: @execStub })
      dogebot = new Dogebot(@robot)

      @robot.on 'dogecoin.sendFrom', (data) =>
        expectedData =
          user:    @user
          address: @fakeAddress
          amount:  amount
          txid:    txid
        done()
      dogebot.sendFrom(@user, @fakeAddress, amount)
