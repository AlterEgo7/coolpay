require "spec_helper"
require 'coolpay/payment'

RSpec.describe Coolpay::Client do
  before do
    @client = Coolpay::Client.new
  end

  describe 'authentication' do
    it 'should have credentials present' do
      expect { @client.authenticate(nil, 'test') }.to raise_error(ArgumentError)
      expect { @client.authenticate('', 'test') }.to raise_error(ArgumentError)
      expect { @client.authenticate('test', '') }.to raise_error(ArgumentError)
      expect { @client.authenticate('test', nil) }.to raise_error(ArgumentError)
    end

    describe 'successful' do
      before do
        stub_request(:post, Coolpay::API_URL + '/login')
          .with(body: { username: 'valid-user', password: 'valid-password' }.to_json)
          .to_return(status: 200, body: { token: 'valid-token' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
        @client.authenticate('valid-user', 'valid-password')
      end

      it 'should have receive authentication token' do
        expect(@client.token).to eq 'valid-token'
      end
    end

    describe 'unsuccessful' do
      before do
        stub_request(:post, Coolpay::API_URL + '/login')
          .with(body: { username: 'valid-user', password: 'valid-password' }.to_json)
          .to_return(status: 404, body: 'Internal Server Error',
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'should raise exception' do
        expect { @client.authenticate('valid-user', 'valid-password') }
          .to raise_error(Coolpay::AuthenticationError)
      end
    end
  end

  describe 'recipient addition' do
    it 'should have name present' do
      expect { @client.add_recipient('') }.to raise_error ArgumentError
      expect { @client.add_recipient(nil) }.to raise_error ArgumentError
    end

    describe 'successful' do

      before do
        stub_request(:post, Coolpay::API_URL + '/login')
          .with(body: { username: 'valid-user', password: 'valid-password' }.to_json)
          .to_return(status: 200, body: { token: 'valid-token' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        stub_request(:post, Coolpay::API_URL + '/recipients')
          .with(body: { name: 'recipient' }.to_json)
          .to_return(status: 201, body: { name: 'recipient', id: '123456' }.to_json,
                     headers: { 'Content-Type' => 'application/json',
                                'Authorization' => 'Bearer valid-token' })
        @client.authenticate('valid-user', 'valid-password')
      end

      it 'should return new Recipient' do
        expect(@client.add_recipient('recipient')).to eq Coolpay::Recipient.new('recipient', '123456')
      end
    end

    describe 'unsuccessful' do
      before do
        stub_request(:post, Coolpay::API_URL + '/recipients')
          .with(body: { name: 'recipient' }.to_json)
          .to_return(status: 401)
      end

      it 'should raise ApiError' do
        expect { @client.add_recipient('recipient') }.to raise_error Coolpay::UnauthorizedError
      end
    end
  end

  describe 'get recipients' do
    describe 'successful' do
      before do
        stub_request(:post, Coolpay::API_URL + '/login')
          .with(body: { username: 'valid-user', password: 'valid-password' }.to_json)
          .to_return(status: 200, body: { token: 'valid-token' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, Coolpay::API_URL + '/recipients')
          .to_return(status: 200, body: { recipients: [{ name: 'recipient', id: '123456' },
                                                       { name: 'recipient2', id: '654321' }] }.to_json,
                     headers: { 'Content-Type' => 'application/json',
                                'Authorization' => 'Bearer valid-token' })
        @client.authenticate('valid-user', 'valid-password')
      end

      it 'should return Recipient array' do
        expect(@client.get_recipients).to eq [Coolpay::Recipient.new('recipient', '123456'),
                                              Coolpay::Recipient.new('recipient2', '654321')]
      end
    end

    describe 'unsuccessful' do
      before do
        stub_request(:get, Coolpay::API_URL + '/recipients')
          .to_return(status: 401)
      end

      it 'should raise UnauthorizedError' do
        expect { @client.get_recipients }.to raise_error Coolpay::UnauthorizedError
      end
    end
  end

  describe 'create_payment' do
    describe 'successfully' do
      before do
        stub_request(:post, Coolpay::API_URL + '/login')
          .with(body: { username: 'valid-user', password: 'valid-password' }.to_json)
          .to_return(status: 200, body: { token: 'valid-token' }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        stub_request(:post, Coolpay::API_URL + '/payments')
          .with(body: {
            amount: 1.2,
            currency: 'GBP',
            recipient_id: 'test_recipient'
          }, headers: { 'Content-Type' => 'application/json',
                        'Authorization' => 'Bearer valid-token' }).to_return(status: 201, body: { payment: {
            status: 'processing',
            recipient_id: 'test_recipient',
            id: 'payment_id',
            currency: 'GBP',
            amount: '1.20'
          } }.to_json, headers: { 'Content-Type' => 'application/json' })

        @client.authenticate('valid-user', 'valid-password')
      end

      it 'should return a new Payment' do
        expect(@client.create_payment(1.2, 'GBP', 'test_recipient'))
          .to eq Payment.new('status' => 'processing', 'amount' => 1.2,
                             'recipient_id' => 'test_recipient', 'id' => 'payment_id',
                             'currency' => 'GBP')
      end
    end
  end
end
