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
        authenticate_client
      end

      it 'should have receive authentication token' do
        expect(@client.token).to eq 'valid-token'
      end
    end

    describe 'unsuccessful' do
      before do
        stub_request(:post, Coolpay::API_URL + '/login')
          .with(body: { username: 'valid-user', apikey: 'valid-apikey' })
          .to_return(status: 404, body: 'Internal Server Error',
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'should raise exception' do
        expect { @client.authenticate('valid-user', 'valid-apikey') }
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
        authenticate_client

        stub_request(:post, Coolpay::API_URL + '/recipients')
          .with(body: { recipient: { name: 'recipient' } })
          .to_return(status: 201, body: { recipient: { name: 'recipient', id: '123456' } }.to_json,
                     headers: { 'Content-Type' => 'application/json',
                                'Authorization' => 'Bearer valid-token' })
      end

      it 'should return new Recipient' do
        expect(@client.add_recipient('recipient')).to eq Coolpay::Recipient.new('recipient', '123456')
      end
    end

    describe 'unsuccessful' do
      before do
        stub_request(:post, Coolpay::API_URL + '/recipients')
          .with(body: { recipient: { name: 'recipient' } })
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
        authenticate_client

        stub_request(:get, Coolpay::API_URL + '/recipients')
          .to_return(status: 200, body: { recipients: [{ name: 'recipient', id: '123456' },
                                                       { name: 'recipient2', id: '654321' }] }.to_json,
                     headers: { 'Content-Type' => 'application/json',
                                'Authorization' => 'Bearer valid-token' })
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
        authenticate_client

        stub_request(:post, Coolpay::API_URL + '/payments')
          .with(body: { payment: {
            amount: 1.2,
            currency: 'GBP',
            recipient_id: 'test_recipient'
          } }, headers: { 'Content-Type' => 'application/json',
                        'Authorization' => 'Bearer valid-token' }).to_return(status: 201, body: { payment: {
          status: 'processing',
          recipient_id: 'test_recipient',
          id: 'payment_id',
          currency: 'GBP',
          amount: '1.20'
        } }.to_json, headers: { 'Content-Type' => 'application/json' })

      end

      it 'should return a new Payment' do
        expect(@client.create_payment(1.2, 'GBP', 'test_recipient'))
          .to eq Payment.new('status' => 'processing', 'amount' => 1.2,
                             'recipient_id' => 'test_recipient', 'id' => 'payment_id',
                             'currency' => 'GBP')
      end
    end

    describe 'unsuccessfully' do

      before do
        authenticate_client
      end

      describe 'with unprocessable entity' do
        before do
          stub_request(:post, Coolpay::API_URL + '/payments')
            .with(body: { payment: {
              amount: 1.2,
              currency: 'GBP',
              recipient_id: 'non-existent recipient'
            } }, headers: { 'Content-Type' => 'application/json',
                          'Authorization' => 'Bearer valid-token' }).to_return(status: 422, body: 'Unprocessable Entity')
        end

        it 'should raise ArgumentError' do
          expect { @client.create_payment(1.2, 'GBP', 'non-existent recipient') }
            .to raise_error ArgumentError
        end
      end

      describe 'with unauthorised' do
        before do
          stub_request(:post, Coolpay::API_URL + '/payments')
            .with(body: { payment: {
              amount: 1.2,
              currency: 'GBP',
              recipient_id: 'non-existent recipient'
            } }, headers: { 'Content-Type' => 'application/json',
                          'Authorization' => 'Bearer valid-token' }).to_return(status: 401)
        end

        it 'should raise UnauthorizedError' do
          expect { @client.create_payment(1.2, 'GBP', 'non-existent recipient') }
            .to raise_error Coolpay::UnauthorizedError
        end
      end
    end
  end

  describe 'get all payments' do
    describe 'while authorized' do
      before do
        authenticate_client

        @body = [
          {
            'status' => 'failed',
            'recipient_id' => '7e1f5f01-fe20-47b6-ae7c-bb44cb08b2b7',
            'id' => '3c61e144-e040-40b0-8026-1eb9db140c3f',
            'currency' => 'ABC',
            'amount' => '10.3'
          },
          {
            'status' => 'failed',
            'recipient_id' => '7e1f5f01-fe20-47b6-ae7c-bb44cb08b2b7',
            'id' => 'd552f9bd-dc0e-4271-a0c1-3056fb08c304',
            'currency' => 'EUR',
            'amount' => '10.3'
          },
          {
            'status' => 'paid',
            'recipient_id' => '7e1f5f01-fe20-47b6-ae7c-bb44cb08b2b7',
            'id' => '1ee22f70-1d93-4e73-9a2d-7360f42edc0d',
            'currency' => 'GBP',
            'amount' => '10.5'
          }
        ]
        stub_request(:get, Coolpay::API_URL + '/payments')
          .with(headers: { 'Content-Type' => 'application/json', 'Authorization' => 'Bearer valid-token' })
          .to_return(status: 200, body: {
            payments: @body
          }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'should return an array of Payments' do
        expected = @body.map { |options| Payment.new(options) }
        expect(@client.get_payments).to eq expected
      end
    end

    describe 'while unauthorized' do
      before do
        stub_request(:get, Coolpay::API_URL + '/payments').to_return(status: 401)
      end

      it 'should raise UnauthorizedError' do
        expect { @client.get_payments }.to raise_error Coolpay::UnauthorizedError
      end
    end
  end
end
