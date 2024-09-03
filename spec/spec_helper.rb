# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
if ENV["RUBY_CI_SECRET_KEY"]
  require "rspec/core/runner"
  require "ruby_ci/runner_prepend"

  class RSpec::Core::ExampleGroup
    def self.filtered_examples
      rubyci_scoped_ids = Thread.current[:rubyci_scoped_ids] || ""

      RSpec.world.filtered_examples[self].filter do |ex|
        rubyci_scoped_ids == "" || /^#{rubyci_scoped_ids}($|:)/.match?(ex.metadata[:scoped_id])
      end
    end
  end

  RSpec::Core::Runner.prepend(RubyCI::RunnerPrepend)
end

ENV["RAILS_ENV"] = 'test'
ENV["ERRBIT_LOG_LEVEL"] = 'fatal'
ENV["ERRBIT_USER_HAS_USERNAME"] = 'false'

if ENV['COVERAGE']
  require 'coveralls'
  require 'simplecov'
  Coveralls.wear!('rails') do
    add_filter 'bundle'
  end
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ])
  SimpleCov.start('rails') do
    add_filter 'bundle'
  end
end

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'email_spec'
require 'xmpp4r'
require 'xmpp4r/muc'
require 'mongoid-rspec'
require 'fabrication'
require 'sucker_punch/testing/inline'
require 'errbit_plugin/mock_issue_tracker'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
Mongoid::Config.truncate!
Mongoid::Tasks::Database.create_indexes
ActionMailer::Base.delivery_method = :test

RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Mongoid::Matchers, type: :model
  config.alias_example_to :fit, focused: true

  config.before(:each) do
    Mongoid::Config.truncate!
  end

  config.include Haml, type: :helper
  config.include Haml::Helpers, type: :helper
  config.before(:each, type: :helper) do |_|
    init_haml_helpers
  end

  config.before(:each, type: :decorator) do |_|
    Draper::ViewContext.current.class_eval { include Haml::Helpers }
    Draper::ViewContext.current.instance_eval { init_haml_helpers }
  end

  config.infer_spec_type_from_file_location!
end

OmniAuth.config.test_mode = true
