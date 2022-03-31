# frozen_string_literal: true

RSpec.describe StatefulModelRails::StateMachine do
  let(:smi) { classdef.state_machine_instance }
  let(:inst) { classdef.new(initial_state) }
  let(:initial_state) { "StateFrom" }

  let(:state_from) do
    Class.new(StatefulModelRails::StateMachine::State) do
      before_leave { puts "from_before_leave" }
      after_leave { puts "from_after_leave" }
      before_enter { puts "from_before_enter" }
      after_enter { puts "from_after_enter" }
    end
  end

  let(:state_to) do
    Class.new(StatefulModelRails::StateMachine::State) do
      before_leave { puts "to_before_leave" }
      after_leave { puts "to_after_leave" }
      before_enter { puts "to_before_enter" }
      after_enter { puts "to_after_enter" }
    end
  end

  let(:classdef) do
    Class.new do
      def initialize(initial_state)
        @state = initial_state
      end

      def update!(state:)
        @state = state
      end

      def with_lock
        yield if block_given?
      end

      def attributes
        { "state" => @state }
      end

      include StatefulModelRails::StateMachine

      state_machine(on: :state) do
        transition :example1, from: StateFrom, to: StateTo
      end
    end
  end

  before do
    stub_const("StateFrom", state_from)
    stub_const("StateTo", state_to)
  end

  context "with one transition" do
    it "runs enter/exit hooks" do
      expect($stdout).to receive(:puts).with("from_before_leave").ordered
      expect($stdout).to receive(:puts).with("to_before_enter").ordered
      expect($stdout).to receive(:puts).with("from_after_leave").ordered
      expect($stdout).to receive(:puts).with("to_after_enter").ordered

      expect($stdout).not_to receive(:puts).with("from_before_enter").ordered
      expect($stdout).not_to receive(:puts).with("from_after_enter").ordered
      expect($stdout).not_to receive(:puts).with("to_before_leave").ordered
      expect($stdout).not_to receive(:puts).with("to_after_leave").ordered

      inst.example1
    end
  end
end
