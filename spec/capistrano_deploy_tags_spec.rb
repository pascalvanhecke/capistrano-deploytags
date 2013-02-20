require 'capistrano'
require 'capistrano-spec'
require 'fileutils'
mypath = File.expand_path(File.dirname(__FILE__))
require File.expand_path(File.join(mypath, '..', 'lib', 'capistrano', 'deploy_tags'))

describe Capistrano::DeployTags do
  let(:configuration) { Capistrano::Configuration.new }
  let(:tmpdir) { "/tmp/#{$$}" }
  let(:mypath) { mypath }

  before :each do
    Capistrano::DeployTags.load_into(configuration)
  end

  def with_clean_repo(&block)
    FileUtils.rm_rf tmpdir
    FileUtils.mkdir tmpdir
    FileUtils.chdir tmpdir
    raise unless system("/usr/bin/tar xzf #{File.join(mypath, 'fixtures', 'git-fixture.tar.gz')}")
    FileUtils.chdir "#{tmpdir}/git-fixture"
    yield
    FileUtils.rm_rf tmpdir
  end

  context "prepare_tree" do
    it "raises an error when not in a git tree" do
      FileUtils.chdir '/tmp'
      configuration.set(:branch, 'master')
      configuration.set(:stage, 'test')
      expect { configuration.find_and_execute_task('git:prepare_tree') }.to raise_error('git checkout master failed!')
    end

    context "with a clean git tree" do
      it "raises an error if :stage or :branch are undefined" do
        with_clean_repo do
          expect { configuration.find_and_execute_task('git:prepare_tree') }.to raise_error('define :branch and :stage')
        end
      end

      it "does not raise an error when run from a clean tree" do
        with_clean_repo do
          configuration.set(:branch, 'master')
          configuration.set(:stage, 'test')
          expect { configuration.find_and_execute_task('git:prepare_tree') }.to_not raise_error
        end
      end
    end
  end

  context "tagdeploy" do
    before :each do
      configuration.set(:branch, 'master')
      configuration.set(:stage, 'test')
    end

    it "does not raise an error when run from a clean tree" do
      with_clean_repo do
        expect { configuration.find_and_execute_task('git:tagdeploy') }.to_not raise_error
      end
    end

    it "adds appropriate git tags" do
      with_clean_repo do
        configuration.find_and_execute_task('git:tagdeploy')

        tags = `git tag -l`.split(/\n/)
        tags.should have(1).items
        tags.first.should =~ /^test-\d{4}\.\d{2}\.\d{2}/
      end
    end

    it "can read the config" do
      y configuration.task_list(:all).map(&:name)
      y configuration.task_list(:all)
    end
  end
end
