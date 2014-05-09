require 'spec_helper'

describe ::GitReview::User do

  subject { ::GitReview::User.new }

  it 'has accessible attributes' do
    subject.should be_accessible
  end

end
