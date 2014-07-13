module GitReview

  module Provider

    class Bitbucket < Base

      def request(number, repo = source_repo)
        raise ::GitReview::InvalidRequestIDError unless number
        Request.from_bitbucket(server, client.pull_request(repo, number))
      rescue Bucketkit::NotFound
        raise ::GitReview::InvalidRequestIDError
      end

      def requests(repo = source_repo)
        Request.from_bitbucket(server, client.pull_requests(repo))
      end

      def request_comments(number, repo = source_repo)
        Comment.from_bitbucket(server, client.request_comments(repo, number))
      end

      def create_request(repo, base, head, title, body)
        # TODO: See whether we can form a Request instance from the response.
        client.create_request(repo, base, head, title, body)
      end

      def commits(number, repo = source_repo)
        Commit.from_bitbucket(server, client.commits(repo, number))
      end

      def commit_comments(sha, repo = source_repo)
        Comment.from_bitbucket(server, client.commit_comments(repo, sha))
      end

      def url_for_request(repo, number)
        "https://bitbucket.com/#{repo}/pull/#{number}"
      end

      def url_for_remote(repo)
        "git@bitbucket.com:#{repo}.git"
      end


      private

      def url_matching(url)
        matches = /bitbucket\.com.(.*?)\/(.*)/.match(url)
        matches ? [matches[1], matches[2].sub(/\.git\z/, '')] : [nil, nil]
      end

      def insteadof_matching(config, url)
        first_match = config.keys.collect { |key|
          [config[key], /url\.(.*bitbucket\.com.*)\.insteadof/.match(key)]
        }.find { |insteadof_url, true_url|
          url.index(insteadof_url) and true_url != nil
        }
        first_match ? [first_match[0], first_match[1][1]] : [nil, nil]
      end

      def configure_access
        @client = Bucketkit::Client.new
        @client.login
      end

    end

  end

end
