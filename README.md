# Coolpay

Simple Ruby Client for the Coolpay API

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'coolpay'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install coolpay

## Assumptions

* API backend ensures ID uniqueness.

* Considered amount can be float for simplicity. In reality, a BigDecimal
or money gem should be used, to handle real currencies and most importantly
handle sub-cent amounts and rounding, and also avoid errors 
due to float representation.

* I have considered security issues arising from saving the API access
token as a file in the user's directory. Here, I settled with a cleartext 
file with stricter permissions. In reality, if this is a 
sensitive API, this token might need to be encrypted.

## Usage

The gem includes a Ruby client, as well as a CLI application for interacting
with the Coolpay API.

The ClI designed is heavily influenced from Docker CLI. The [GLI](https://github.com/davetron5000/gli)
gem was used. The CLI executable is in the 'exe' directory.

To list all commands available:
```
coolpay
```

To login:
```
coolpay login -u <username> -p <apikey>
```
Successfully logging in will save the token at ~/.coolpay

To create a new recipient:
```
coolpay recipient create <name>
```

To list all payments:
```
coolpay payment ls
```

To view a specific payment:
```
coolpay payment ls --id=<payment_id>
```

To create a payment:
```
coolpay payment create --amount=<maount> --currency=<currency> recipients
```

## Notes

* This is the first time I decided to create a small CLI app. The design
is heavily influenced by the Docker CLI.

* The core is the Client class which can be used by developers for
abstracting calls to the API. THe CLI app is just built on top of it.

* The CLI allows getting the info for a single payment (checking its status).
This is done on the presentation layer (app filters results from client) as
the API itself does not allow searching payments. It was a design decision
whether to create a Client method to provide this, or delegate it to the 
presentation layer. I chose the latter, to make the API functionality clear 
to the end users.