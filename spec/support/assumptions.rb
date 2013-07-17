# Assumptions are basically stubs that allow the actual specs to focus on what
# is relevant to the test at hand. It improves readability and implies that
# these assumptions have been made to navigate through the code.

def assume_silence
  ::GitReview::GitReview.any_instance.stub(:puts)
end

def assume(name, value)
  subject.instance_variable_set name, value
end

def assume_arguments(*arguments)
  assume :@args, arguments
end

def assume_requests(*requests)
  requests = [request] if requests.empty?
  assume :@current_requests, requests
end

def assume_no_requests
  assume :@current_requests, []
end

def assume_added_to(collection, new_item)
  array = subject.instance_variable_get(collection) || []
  array << new_item
  subject.instance_variable_set collection, array
end

def assume_valid_request_id
  assume :@args, [request_id]
  assume :@current_requests, [request]
end

def assume_request_on_github(found = true, override = nil)
  response = override || (found ? request : ::GitReview::Request.new)
  github.stub(:pull_request).with(source_repo, request_id).and_return(response)
end

def assume_requests_on_github(found = true)
  response = found ? [request] : []
  github.stub(:pull_requests).with(source_repo, 'open').and_return(response)
end

def assume_request_closed(closed = true)
  request.state = closed ? 'closed' : 'open'
end

def assume_on_master
  subject.stub(:git_call).with('branch').and_return("* master\n")
end

def assume_on_feature_branch
  subject.stub(:on_feature_branch?).and_return(true)
  subject.stub(:git_call).with('branch').and_return(
    " master\n* #{branch_name}\n"
  )
end

def assume_feature_branch(branch_exists = true)
  branches = branch_exists ? "* master\n  #{branch_name}\n" : "* master\n"
  subject.stub(:git_call).with('branch -a').and_return(branches)
end

def assume_feature_branch(branch_name='foo')
  ::GitReview::Local.instance.stub(:git_call).with('branch -a').
      and_return("* master\n  #{branch_name}\n")
end

def assume_no_feature_branch
  ::GitReview::Local.instance.stub(:git_call).with('branch -a').
      and_return("* master\n")
end

def assume_branch_exist(location = :local, exists = true)
  subject.stub(:branch_exists?).with(location, branch_name).and_return(exists)
end

def assume_branch_exists(location=:local, branch_name='foo')
  ::GitReview::Local.instance.stub(:branch_exists?).with(location, branch_name).
      and_return(true)
end

def assume_branch_not_exists(location=:local, branch_name='foo')
  ::GitReview::Local.instance.stub(:branch_exists?).with(location, branch_name).
      and_return(false)
end

def assume_custom_target_branch_defined
  ENV.stub(:[]).with('TARGET_BRANCH').and_return(custom_target_name)
end

def assume_change_branches(direction = nil)
  if direction
    branches = ["* master\n  #{branch_name}\n", "  master\n* #{branch_name}\n"]
    if direction.keys.first == :feature
      on_feature = true
      branches.reverse!
    else
      on_feature = false
    end
    subject.stub(:on_feature_branch?).and_return(on_feature)
    subject.stub(:git_call).with('branch').and_return(*branches)
  end
  subject.stub(:git_call).with(include 'checkout')
end

def assume_merged(merged = true)
  subject.stub(:merged?).with(head_sha).and_return(merged)
end

def assume_uncommitted_changes(changes_exist = true)
  changes = changes_exist ? ['changes'] : []
  subject.stub(:git_call).with('diff HEAD').and_return(changes)
end

def assume_local_commits(commits_exist = true)
  commits = commits_exist ? ['commits'] : []
  subject.stub(:git_call).with('cherry master').and_return(commits)
end

def assume_title_and_body_set
  subject.stub(:create_title_and_body).and_return([title, body])
end

def assume_create_pull_request
  subject.stub(:git_call).with(
    "push --set-upstream origin #{branch_name}", false, true
  )
  assume_updated
  github.stub(:create_pull_request).with(
    source_repo, 'master', branch_name, title, body
  )
end

def assume_updated
  ::GitReview::Github.instance.stub(:update)
end

def assume_pruning
  subject.stub(:git_call).with('remote prune origin')
end

def assume_unmerged_commits(commits_exist = true)
  subject.stub(:unmerged_commits?).with(branch_name).and_return(commits_exist)
  subject.stub(:unmerged_commits?).with(branch_name, verbose = false).
    and_return(commits_exist)
end

def assume_unmerged_commits
  ::GitReview::Local.instance.stub(:unmerged_commits?).and_return(true)
end


def assume_no_unmerged_commits
  ::GitReview::Local.instance.stub(:unmerged_commits?).and_return(false)
end

def assume_valid_command(valid = true)
  assume_arguments command
  subject.stub(:respond_to?).and_return(valid)
end

def assume_valid_command
  ::GitReview::Commands.stub(:respond_to?).and_return(true)
end

def assume_invalid_command
  ::GitReview::Commands.stub(:respond_to?).and_return(false)
end

def assume_repo_info_set
  subject.stub(:repo_info).and_return([user, repo])
end

def assume_github_configured
  ::GitReview::Github.instance.stub(:configure_github_access).and_return(true)
end

def assume_source_repo_set
  ::GitReview::Github.instance.stub(:source_repo).and_return('foo')
end

def assume_error_raised
  subject.stub(:help).and_raise(::GitReview::Errors::UnprocessableState)
end

def assume_config_file_exists(home_dir=nil, config_file=nil)
  Dir.stub(:home).and_return(home_dir)
  File.stub(:exists?).with(config_file).and_return(true)
end

def assume_config_file_loaded(home_dir=nil, config_file=nil)
  assume_config_file_exists(home_dir, config_file)
  YAML.stub(:load_file).with(config_file)
end

def assume_token_present
  ::GitReview::Settings.instance.stub(:username).and_return('username')
  ::GitReview::Settings.instance.stub(:oauth_token).and_return('some_valid_token')
end

def assume_token_missing
  ::GitReview::Settings.instance.stub(:oauth_token).and_return(nil)
end

def assume_request_not_found
  ::GitReview::Github.instance.stub(:pull_request).and_raise(Octokit::NotFound)
end

def assume_open_request(request=nil)
  r = request || Hashie::Mash.new
  r.state = 'open'
  ::GitReview::Github.instance.stub(:pull_request).and_return(r)
end

def assume_closed_request(request=nil)
  r = request || Hashie::Mash.new
  r.state = 'closed'
  ::GitReview::Github.instance.stub(:pull_request).and_return(r)
end