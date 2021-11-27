# frozen_string_literal: true

require "bundler/setup"
require "stateful_model_rails"
require 'ruby_jard'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

class StateA < StatefulModelRails::StateMachine::State; end

class StateB < StatefulModelRails::StateMachine::State; end

class StateC < StatefulModelRails::StateMachine::State; end
