require_relative '../spec_helper'
require_relative '../support/request_context'

describe 'Commands' do

  include_context 'request_context'

  subject { ::GitReview::Commands }
  let(:github) { ::GitReview::Github.any_instance }
  let(:local) { ::GitReview::Local.any_instance }

  before(:each) do
    github.stub(:configure_github_access).and_return('username')
  end

  describe '#help' do

    it 'shows the help page' do
      subject.should_receive(:puts).with(/Usage: git review <command>/)
      subject.help
    end

  end

  describe '#list' do

    before(:each) do
      local.stub(:source).and_return('some_source')
    end

    context 'when listing all unmerged pull requests' do

      let(:req1) { request.clone }
      let(:req2) { request.clone }

      before(:each) do
        req1.title, req2.title = 'first', 'second'
        github.stub(:current_requests_full).and_return([req1, req2])
        local.stub(:merged?).and_return(false)
      end

      it 'shows them' do
        subject.stub(:next_arg)
        subject.should_receive(:puts).with(/Pending requests for 'some_source'/)
        subject.should_not_receive(:puts).with(/No pending requests/)
        subject.should_receive(:print_request).with(req1).ordered
        subject.should_receive(:print_request).with(req2).ordered
        subject.list
      end

      it 'sorts the output with --reverse option' do
        subject.stub(:next_arg).and_return('--reverse')
        subject.stub(:puts)
        subject.should_receive(:print_request).with(req2).ordered
        subject.should_receive(:print_request).with(req1).ordered
        subject.list
      end

    end

    context 'when pull requests are already merged' do

      before(:each) do
        github.stub(:current_requests_full).and_return([request])
        local.stub(:merged?).and_return(true)
      end

      it 'does not list them' do
        subject.stub(:next_arg)
        subject.should_receive(:puts).
            with(/No pending requests for 'some_source'/)
        subject.should_not_receive(:print_request)
        subject.list
      end

    end

    it 'knows when there are no open pull requests' do
      github.stub(:current_requests_full).and_return([])
      subject.stub(:next_arg)
      subject.should_receive(:puts).
          with(/No pending requests for 'some_source'/)
      subject.should_not_receive(:print_request)
      subject.list
    end

  end

  describe '#show' do

    it 'requires an ID' do
      subject.stub(:next_arg).and_return(nil)
      expect { subject.show }.to raise_error(::GitReview::InvalidRequestIDError)
    end

    it 'requires a valid request number' do
      subject.stub(:next_arg).and_return(0)
      github.stub(:request_exists?).and_return(false)
      expect { subject.show }.to raise_error(::GitReview::InvalidRequestIDError)
    end

    context 'when the pull request number is valid' do

      before(:each) do
        subject.stub(:get_request_or_return).and_return(request)
        subject.stub(:puts)
      end

      it 'shows stats of the request' do
        subject.stub(:next_arg).and_return(nil)
        subject.should_receive(:git_call).
            with("diff --color=always --stat HEAD...#{head_sha}")
        subject.stub(:print_request_details)
        subject.stub(:print_request_discussions)
        subject.show
      end

      it 'shows full diff with --full option' do
        subject.stub(:next_arg).and_return('--full')
        subject.should_receive(:git_call).
            with("diff --color=always HEAD...#{head_sha}")
        subject.stub(:print_request_details)
        subject.stub(:print_request_discussions)
        subject.show
      end

    end

  end

  describe '#browse' do

    it 'requires an valid ID' do
      subject.stub(:next_arg).and_return(nil)
      expect { subject.browse }.
          to raise_error(::GitReview::InvalidRequestIDError)
    end

    it 'opens the pull request page on GitHub in a browser' do
      subject.stub(:get_request_or_return).and_return(request)
      Launchy.should_receive(:open).with(html_url)
      subject.browse
    end

  end

  describe '#checkout' do

    it 'requires an valid ID' do
      subject.stub(:next_arg).and_return(nil)
      expect { subject.checkout }.
          to raise_error(::GitReview::InvalidRequestIDError)
    end

    context 'when the request is valid' do

      before(:each) do
        subject.stub(:get_request_or_return).and_return(request)
      end

      it 'creates a headless state in the local repo with the requests code' do
        subject.stub(:next_arg)
        subject.should_receive(:git_call).with("checkout pr/#{request_number}")
        subject.checkout
      end

      it 'creates a local branch if the optional param --branch is appended' do
        subject.stub(:next_arg).and_return('--branch')
        subject.should_receive(:git_call).with("checkout #{head_ref}")
        subject.checkout
      end

    end

  end

  describe '#approve' do

    it 'requires an valid ID' do
      subject.stub(:next_arg).and_return(nil)
      expect { subject.approve }.
          to raise_error(::GitReview::InvalidRequestIDError)
    end

    context 'when the request is valid' do

      before(:each) do
        subject.stub(:get_request_or_return).and_return(request)
        github.stub(:source_repo).and_return('some_source')
      end

      it 'posts an approving comment in your name to the requests page' do
        comment = 'Reviewed and approved.'
        github.should_receive(:add_comment).
          with('some_source', request_number, 'Reviewed and approved.').
          and_return(:body => comment)
        subject.should_receive(:puts).with(/Successfully approved request./)
        subject.approve
      end

      it 'outputs any errors that might occur when trying to post a comment' do
        message = 'fail'
        github.should_receive(:add_comment).
          with('some_source', request_number, 'Reviewed and approved.').
          and_return(:body => nil, :message => message)
        subject.should_receive(:puts).with(message)
        subject.approve
      end

    end

  end

  describe '#merge' do

    it 'requires an valid ID' do
      subject.stub(:next_arg).and_return(nil)
      expect { subject.merge }.
          to raise_error(::GitReview::InvalidRequestIDError)
    end

    context 'when the request is valid' do

      before(:each) do
        subject.stub(:get_request_or_return).and_return(request)
        subject.stub(:next_arg)
        github.stub(:source_repo)
      end

      it 'does not proceed if source repo no longer exists' do
        request.head.stub(:repo).and_return(nil)
        subject.should_receive(:print_repo_deleted)
        subject.should_not_receive(:git_call)
        subject.merge
      end

      it 'merges the request with your current branch' do
        msg = "Accept request ##{request_number} " +
            "and merge changes into \"/master\""
        subject.should_receive(:git_call).with("merge  -m '#{msg}' #{head_sha}")
        subject.stub(:puts)
        subject.merge
      end

    end

  end

  describe '#close' do

    it 'requires an valid ID' do
      subject.stub(:next_arg).and_return(nil)
      subject.should_receive(:puts).with('Please specify a valid ID.')
      subject.close
    end

    it 'closes the request' do
      subject.stub(:next_arg)
      github.stub(:request_exists?).and_return(request)
      github.stub(:source_repo).and_return('some_source')
      github.should_receive(:close_issue).with('some_source', request_number)
      github.should_receive(:request_exists?).
        with('open', request_number).and_return(false)
      subject.should_receive(:puts).with(/Successfully closed request./)
      subject.close
    end

  end

  describe '#prepare' do

    context 'when on master branch' do

      before(:each) do
        local.stub(:source_branch).and_return('master')
        local.stub(:target_branch).and_return('master')
        subject.stub(:puts)
      end

      it 'creates a local branch with review prefix' do
        subject.stub(:next_arg).and_return(feature_name)
        subject.should_receive(:git_call).with("checkout -b #{branch_name}")
        subject.stub(:git_call)
        subject.prepare
      end

      it 'lets the user choose a name for the branch' do
        subject.stub(:next_arg).and_return(nil)
        subject.should_receive(:gets).and_return(feature_name)
        subject.should_receive(:git_call).with("checkout -b #{branch_name}")
        subject.stub(:git_call)
        subject.prepare
      end

      it 'creates a local branch when TARGET_BRANCH is defined' do
        subject.stub(:next_arg).and_return(feature_name)
        ENV.stub(:[]).with('TARGET_BRANCH').and_return(custom_target_name)
        subject.should_receive(:git_call).with("checkout -b #{branch_name}")
        subject.stub(:git_call)
        subject.prepare
      end

      it 'sanitizes provided branch names' do
        subject.stub(:next_arg).and_return('wild stuff?')
        subject.should_receive(:git_call).with(/wild_stuff/)
        subject.stub(:git_call)
        subject.prepare
      end

      #it 'moves uncommitted changes to the new branch' do
      #  subject.stub(:next_arg).and_return(feature_name)
      #  local.stub(:uncommited_changes?).and_return(true)
      #  local.stub(:source_branch).and_return(branch_name)
      #  subject.stub(:git_call)
      #  subject.should_receive(:git_call).with('stash')
      #  subject.prepare
      #end
      #
      #it 'moves unpushed commits to the new branch' do
      #  assume_change_branches :master => :feature
      #  assume_arguments feature_name
      #  assume_uncommitted_changes false
      #  subject.should_receive(:git_call).with(include 'reset --hard')
      #  subject.prepare
      #end

    end

  end

  #describe '#create' do
  #
  #  context 'when on feature branch' do
  #
  #    before(:each) do
  #      local.stub(:source_branch).and_return(feature_name)
  #      local.stub(:target_branch).and_return(feature_name)
  #    end
  #
  #  end
  #
  #  it 'warns the user about uncommitted changes' do
  #    assume_uncommitted_changes
  #    subject.should_receive(:puts).with(include 'uncommitted changes')
  #    subject.create
  #  end
  #
  #  it 'pushes the commits to a remote branch and creates a pull request' do
  #    assume_no_requests
  #    assume_on_feature_branch
  #    assume_uncommitted_changes false
  #    assume_local_commits
  #    assume_title_and_body_set
  #    assume_change_branches
  #    subject.should_receive(:git_call).with(
  #      "push --set-upstream origin #{branch_name}", false, true
  #    )
  #    subject.should_receive :update
  #    github.should_receive(:create_pull_request).with(
  #      source_repo, 'master', branch_name, title, body
  #    )
  #    subject.create
  #  end
  #
  #  it 'lets the user return to the branch she was working on before' do
  #    assume_no_requests
  #    assume_uncommitted_changes false
  #    assume_local_commits
  #    assume_title_and_body_set
  #    assume_create_pull_request
  #    assume_on_feature_branch
  #    subject.should_receive(:git_call).with('checkout master').ordered
  #    subject.should_receive(:git_call).with("checkout #{branch_name}").ordered
  #    subject.create
  #  end
  #
  #end

  describe '#clean' do

    before(:each) do
      subject.stub(:git_call).with('remote prune origin')
    end

    it 'requires either an ID or the additional parameter --all' do
      subject.instance_variable_set(:@args, [])
      subject.should_receive(:puts).with(/either an ID or "--all"/)
      subject.clean
    end

    it 'removes a single obsolete branch with review prefix' do
      subject.instance_variable_set(:@args, [request_number])
      local.should_receive(:clean_single).with(request_number)
      subject.clean
    end

    it 'removes all obsolete branches with review prefix' do
      subject.instance_variable_set(:@args, ['--all'])
      local.should_receive(:clean_all)
      subject.clean
    end

    it 'deletes a branch with unmerged changes with --force option' do
      subject.instance_variable_set(:@args, [request_number, '--force'])
      local.should_receive(:clean_single).with(request_number, force = true)
      subject.clean
    end

  end

end
