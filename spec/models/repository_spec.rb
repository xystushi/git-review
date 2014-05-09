require 'spec_helper'

describe ::GitReview::Repository do

  subject { ::GitReview::Repository.new }

  it 'has accessible attributes' do
    subject.should be_accessible
  end

end
