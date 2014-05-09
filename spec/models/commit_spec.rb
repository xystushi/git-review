require 'spec_helper'

describe ::GitReview::Commit do

  subject { ::GitReview::Commit.new }

  it 'has accessible attributes' do
    subject.should be_accessible
  end

  it 'has a nested attribute :user' do
    subject.user.class.should == ::GitReview::User
  end

end
