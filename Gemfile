source 'http://rubygems.org'
gemspec

gem 'bucketkit', github: 'xystushi/bucketkit', branch: 'master'

group :debug do
  gem 'byebug' if RUBY_VERSION =~ /^2/
  gem 'ruby-debug' if RUBY_VERSION =~ /^1.9/
end

group :test do
  gem 'rake'
end
