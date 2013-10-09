require_relative '../spec_helper'

describe 'Server' do

  describe '#instance' do

    subject { ::GitReview::Server }

    it 'creates a unique provider instance' do
      subject.stub(:fetch_origin_url).and_return('git@bitbucket.org:foo/bar.git')
      subject.instance.object_id.should equal(subject.instance.object_id)
    end

    context 'for bitbucket repositories' do

      let(:bitbucket) { ::GitReview::Bitbucket.any_instance }

      before :each do
        bitbucket.stub(:configure_access).and_return('username')
      end

      it 'returns a bitbucket provider instance' do
        subject.any_instance.stub(:fetch_origin_url).and_return('git@bitbucket.org:foo/bar.git')
        subject.new.provider.should be_an_instance_of(::GitReview::Bitbucket)
      end

    end

    context 'for github repositories' do

      let(:github) { ::GitReview::Github.any_instance }

      before :each do
        github.stub(:configure_access).and_return('username')
      end

      it 'returns a github provider instance' do
        subject.any_instance.stub(:fetch_origin_url).and_return('git@github.com:foo/bar.git')
        subject.new.provider.should be_an_instance_of(::GitReview::Github)
      end

    end

  end

end