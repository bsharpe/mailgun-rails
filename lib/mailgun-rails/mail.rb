module MailgunRails
  class Mail
    def initialize(settings)
      @settings = settings
    end
    attr_accessor :settings

    def deliver!(mail)
      # Max size for a message to be sent with mailgun's API is 25k
      if (mail.to_s.size <= 25*1024)
        RestClient.post message_url, message_params(mail)
      else
        # send by SMTP
      end
    end
    
    private

    def message_url
      "https://api:#{settings[:api_key]}@api.mailgun.net/v2/#{settings[:api_host]}/messages"
    end

    def message_params(mail)
      data = MultiMap.new
      data[:subject] = mail.subject
      params_to_map = { from: ' ', to: ', ', bcc: ', ', cc: ', ' }
      
      params_to_map.each do |param, joiner|
        data[param] = mail.send(param).join(joiner)
      end
      
      # Handle Mailgun variables
      if (mail.header['X-Mailgun-Variables'])
        data['v:my-custom-data'] = mail.header['X-Mailgun-Variables']
      end
      
      # Handle Mailgun Tracking
      if (mail.header['X-Mailgun-Track'])
        data['o:tracking'] = (mail.header['X-Mailgun-Track'].downcase == 'yes')
      end
      
      # Handle Mailgun Click Tracking
      if (mail.header['X-Mailgun-Track-Clicks'])
        # REST API doesn't support click tracking option
      end
      
      # Handle Mailgun Open Tracking
      if (mail.header['X-Mailgun-Track-Opens'])
        # REST API doesn't support open tracking option
      end
      
      # Handle Mailgun Campaign 
      if (mail.header['X-Mailgun-Campaign-Id'])
        data['o:campaign'] = mail.header['X-Mailgun-Campaign-Id']
      end
      
      # Handle Mailgun Deliver-By
      if (mail.header['X-Mailgun-Deliver-By'])
        data['o:deliverytime'] = mail.header['X-Mailgun-Deliver-By']
      end
      
      # Handle Mailgun Tags
      if (mail.header['X-Mailgun-Tag'])
        # up to 3 tags can be sent
        tags = mail.header['X-Mailgun-Tag']
        tags[0..2].each do |t|
          data['o:tag'] = t
        end
      end

      type = mail.content_type.match(/html/) ? :html : :text
      
      data[type] = mail.body.to_s

      data
    end
  end
end
