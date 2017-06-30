require "spec_helper"
require 'httparty'
require 'coolpay'

RSpec.describe Coolpay do
  before do
    @coolpay = Coolpay.new
  end

  describe 'authentication' do

    it 'should have credentials present' do
      expect { @coolpay.authenticate(nil, 'test') }.to raise_error(ArgumentError)
      expect { @coolpay.authenticate('', 'test') }.to raise_error(ArgumentError)
      expect { @coolpay.authenticate('test', '') }.to raise_error(ArgumentError)
      expect { @coolpay.authenticate('test', nil) }.to raise_error(ArgumentError)
    end

    describe 'successful' do
      before do
        stub_request(:post, Coolpay::LOGIN_URL)
          .with(body: { username: 'valid-user', password: 'valid-password' }.to_json)
          .to_return(status: 200, body: { token: 'valid-token' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
        @coolpay.authenticate('valid-user', 'valid-password')
      end

      it 'should have receive authentication token' do
        expect(@coolpay.token).to eq 'valid-token'
      end
    end

    describe 'unsuccessful' do
      before do
        stub_request(:post, Coolpay::LOGIN_URL)
          .with(body: { username: 'valid-user', password: 'valid-password' }.to_json)
          .to_return(status: 404, body: 'Internal Server Error',
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'should raise exception' do
        expect { @coolpay.authenticate('valid-user', 'valid-password') }
          .to raise_error(Coolpay::AuthenticationError)
      end
    end
  end
end
