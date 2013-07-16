require_relative '../spec_helper'

describe 'Github' do

  describe '#configure_github_access' do

    subject { ::GitReview::Github }
    let(:settings) { ::GitReview::Settings.any_instance }

    it 'only authenticates once' do
      settings.stub(:oauth_token).and_return('token')
      settings.stub(:username).and_return('username')
      subject.any_instance.should_not_receive(:configure_oauth)
      subject.new.configure_github_access
    end

  end

  describe '#github_url_matching' do

    subject { ::GitReview::Github.new }

    it 'extracts info from git url' do
      url = 'git@github.com:xystushi/git-review.git'
      subject.send(:github_url_matching, url).should == %w(xystushi git-review)
    end

    it 'extracts info from http url' do
      url = 'https://github.com/xystushi/git-review.git'
      subject.send(:github_url_matching, url).should == %w(xystushi git-review)
    end

  end

  describe '#github_insteadof_matching' do

    subject { ::GitReview::Github.new }

    it 'from insteadof url' do
      url = 'git@github.com:foo/bar.git'
      config = {
          'url.git@github.com:a/b.git.insteadof' =>
              'git@github.com:foo/bar.git'
      }
      subject.send(:github_insteadof_matching, config, url).
          should == %w(git@github.com:foo/bar.git git@github.com:a/b.git)
    end

  end

end