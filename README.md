# hubot-dogecoin [![Build Status](https://travis-ci.org/jico/hubot-dogecoin.svg?branch=travis)](https://travis-ci.org/jico/hubot-dogecoin)

A hubot script for tipping with Dogecoin.

![dogecoin](http://i.imgur.com/klX8aS3l.png)

## API

* `<user> +<n> doge` - tip <user> <n> dogecoin (user by mention name)
* `doge register` - get your dogecoin address
* `doge address`  - get your dogecoin address
* `doge balance`  - get your dogecoin balance
* `send <n|all> doge to <addr>` - withdraw <n> or all doge to a dogecoin address

You can swap the _doge_ keyword for one of _such_, _much_, _so_, _very_, or _dogecoin_. I.e. `such address`.

## Requirements

1. [Hubot brain](https://github.com/github/hubot/blob/master/docs/scripting.md#persistence)
2. A [dogecoind](https://github.com/dogecoin/dogecoin) instance running either locally or on another box with the JSON RPC port open (default: 22555).
3. Some dogecoin to give.

## Installation

Add `hubot-dogecoin` as a dependency in your Hubot `package.json`.
```
"dependencies": {
  "hubot": "*",
  "hubot-dogecoin": "~0.0.1"
}
```

Run the following to install the package and its dependencies.
```bash
$ npm install
```

Add `hubot-dogecoin` to the array in `external-scripts.json`, you may need to create this file.
```
['hubot-dogecoin']
```

Configure the following environment variables in `bin/hubot`.
```bash
export HUBOT_DOGECOIND_USER="dogecoindrpcuser"
export HUBOT_DOGECOIND_PASS="dogecoindrpcpass"

export HUBOT_DOGECOIND_HOST="localhost" # optional, default: localhost
export HUBOT_DOGECOIND_PORT=22555       # Optional, default: 22555
```

## Events

The following event hooks are emitted on successful dogecoind command
executions.

```coffee
@robot.emit 'dogecoin.getAddress', { user: user, address: result }
```

```coffee
@robot.emit 'dogecoin.getBalance', { user: user, balance: result }
```

```coffee
@robot.emit 'dogecoin.move', {
  sender:    sender
  recipient: recipient
  amount:    amount
}
```

```coffee
@robot.emit 'dogecoin.sendFrom', {
  user:    user
  address: address
  amount:  amount
  txid:    result
}
```

__Note:__ `user` is the entire user object from `@robot.brain` and `result` is
the result of the corresponding dogecoind command.
