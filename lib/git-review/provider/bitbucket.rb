require 'faraday_middleware'
require 'OAuth'

module GitReview

  # BitBucket specific constructor for git-review's request model.
  class Request
    def self.from_bitbucket(server, response)
       self.new(
           server: server,
           number: response['id'],
           title: response['title'],
           body: response['description'],
           state: response['state'],
           updated_at: response['updated_on'],
           html_url: response['links']['html'],
           patch_url: response['links']['diff'],
           head: {
               sha: response['source']['commit']['hash'],

               user: {
                   login: response['author']['username']
               },
               repo: {

               }
           }
       )
    end
  end

  module Provider

    class Bitbucket < Base

      include ::GitReview::Helpers

      attr_reader :bitbucket

      def configure_access
        configure_oauth unless authenticated?
        @client = Bucketkit::Client.new login: settings.username
        @client.login
      end

      def current_requests_full(repo = source_repo)
        @client.pull_requests(repo)
      end

      def request(number)
        @client.pull_request(source_repo, number)
      end

      def request_exists?(number)
        request = request(number)
        !!request
      end

    private

      def configure_oauth
        print_auth_message
        prepare_username
        prepare_password
        prepare_description
        authorize
      end

      def print_auth_message
        puts "Requesting a OAuth token for git-review."
        puts "This procedure will grant access to your public and private "\
        "repositories."
        puts "You can revoke this authorization by visiting the following page: "\
        "https://bitbucket.org/account/user/USERNAME/api"
      end

      def prepare_username
        print "Please enter your BitBucket's username: "
        @username = STDIN.gets.chomp
      end

      def prepare_password
        print "Please enter your BitBucket's password for #{@username} "\
        "(it won't be stored anywhere): "
        @password = STDIN.noecho(&:gets).chomp
      end

      def prepare_description(chosen_description=nil)
        if chosen_description
          @description = chosen_description
        else
          @description = "git-review - #{Socket.gethostname}"
          puts "Please enter a description to associate to this token, it will "\
          "make easier to find it inside of BitBucket's application page."
          puts "Press enter to accept the proposed description"
          print "Description [#{@description}]:"
          user_description = STDIN.gets.chomp
          @description = user_description.empty? ? @description : user_description
        end
      end

      def authorize
        get_consumer_token
        get_access_token
        save_oauth_token
      end

      def get_consumer_token
        @connection = connection
        @connection.basic_auth @username, @password
        response = @connection.post "/1.0/users/#{@username}/consumers" do |req|
          req.body = Yajl.dump(
              {
                  :name => 'git-review',
                  :description => @description
              }
          )
        end
        @consumer_key = response.body['key']
        @consumer_secret = response.body['secret']
      end

      def get_access_token
        consumer = OAuth::Consumer.new(
            @consumer_key, @consumer_secret,
            {
                :site => 'https://bitbucket.org/!api/1.0',
                :authorize_path => '/oauth/authenticate'
            }
        )
        request_token = consumer.get_request_token
        puts "You will be directed to BitBucket's website for authorization."
        puts "You can also visit #{request_token.authorize_url}."
        Launchy.open(request_token.authorize_url)
        puts "After you've authorized the token, enter the verifier code below:"
        verifier = STDIN.gets.chomp
        access_token = request_token.get_access_token(:oauth_verifier => verifier)
        @token = access_token.token
        @token_secret = access_token.secret
      end

      def save_oauth_token
        settings = ::GitReview::Settings.instance
        settings.bitbucket_consumer_key = @consumer_key
        settings.bitbucket_consumer_secret = @consumer_secret
        settings.bitbucket_token = @token
        settings.bitbucket_token_secret = @token_secret
        settings.save!
        puts "OAuth token successfully created.\n"
      end

      def connection(options={})
        connection = Faraday.new('https://api.bitbucket.org') do |c|
          c.request :oauth, oauth_tokens if authenticated?
          c.request :json
          c.response :mashify
          c.response :json
          c.adapter Faraday.default_adapter
        end
        connection.headers[:user_agent] = 'Git-Review'
        connection
      end

      def authenticated?
        settings.bitbucket_consumer_key &&
            settings.bitbucket_consumer_secret &&
            settings.bitbucket_token &&
            settings.bitbucket_token_secret
      end

      def oauth_tokens
        @oauth_tokens ||=
            if authenticated?
              {
                  :consumer_key => settings.bitbucket_consumer_key,
                  :consumer_secret => settings.bitbucket_consumer_secret,
                  :token => settings.bitbucket_token,
                  :token_secret => settings.bitbucket_token_secret
              }
            end
      end

      # extract user and project name from BitBucket URL.
      def url_matching(url)
        matches = /bitbucket\.org.(.*?)\/(.*)/.match(url)
        matches ? [matches[1], matches[2].sub(/\.git\z/, '')] : [nil, nil]
      end

      # look for 'insteadof' substitutions in URL.
      def insteadof_matching(config, url)
        first_match = config.keys.collect { |key|
          [config[key], /url\.(.*bitbucket\.org.*)\.insteadof/.match(key)]
        }.find { |insteadof_url, true_url|
          url.index(insteadof_url) and true_url != nil
        }
        first_match ? [first_match[0], first_match[1][1]] : [nil, nil]
      end

    end

  end

end
