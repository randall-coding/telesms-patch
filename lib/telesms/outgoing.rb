module Telesms
  require 'sendgrid-ruby'
  include SendGrid

  # This class represents an outgoing message.
  class Outgoing
    extend Base

    # @return [String]
    # The FROM address.
    attr_accessor :from

    # @return [String]
    # The TO address (will be concatinated with a provider).
    attr_accessor :to

    # @return [String]
    # The provider for the number.
    attr_accessor :provider

    # @return [String]
    # The message body being sent.
    attr_accessor :message

    # This method creates a new outgoing message and sends it.
    #
    # @param [String] from
    #   The FROM address.
    #
    # @param [String] to
    #   The TO address.
    #
    # @param [String] provider
    #   The provider name.
    #
    # @param [String] message
    #   The message being sent.
    #
    # @return [Mail]
    def self.deliver(from, to, provider, message)
      self.new(from, to, provider, message).deliver
    end

    # This method creates a new outgoing message.
    #
    # @param [String] from
    #   The FROM address.
    #
    # @param [String] to
    #   The TO address.
    #
    # @param [String] provider
    #   The provider name.
    #
    # @param [String] message
    #   The message being sent.
    #
    # @return [Outgoing]
    def initialize(from, to, provider, message)
      @from     = from
      @to       = to
      @provider = provider
      @message  = message
    end

    # This method sends an email message disguised as an SMS message.
    #
    # @return [Mail]
    def deliver
      from = SendGrid::Email.new(email: from)
      to = Email.new(email: formatted_to)
      subject = "Telefio sms from " + from
      content = Content.new(type: 'text/plain', value: sanitized_message)
      mail = SendGrid::Mail.new(from, subject, to, content)

      sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
      response = sg.client.mail._('send').post(request_body: mail.to_json)
      Rails.logger.info "Send Grid Sent the message"
      Rails.logger.info response.status_code
      Rails.logger.info response.body
      Rails.logger.info response.headers

      # Old way
      # Mail.new(from: from, to: formatted_to, body: sanitized_message).deliver!
    end

    # This method formats the TO address to include the provider.
    #
    # @return [String]
    def formatted_to
      "#{to}@#{Base.gateways[@provider][:sms]}" rescue raise "Invalid provider.  Provider: #{@provider}, Base.gateways: #{Base.gateways}"
    end

    # This method sanitizes the message body.
    #
    # @return [String]
    def sanitized_message
      message.to_s[0,140]
    end
  end
end
