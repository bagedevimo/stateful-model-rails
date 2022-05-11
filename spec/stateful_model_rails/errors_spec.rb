# frozen_string_literal: true

require "spec_helper"
require "stateful_model_rails"

RSpec.describe StatefulModelRails::StateMachine do
  let(:classdef) { build_classdef(table) }
  let(:smi) { classdef.state_machine_instance }
  let(:inst) { classdef.new(initial_state) }

  let(:initial_state) { "StateA" }

  def build_classdef(block)
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

      state_machine(on: :state, &block)
    end
  end

  describe "event transitions" do
    context "with one transition" do
      let(:table) do
        proc do
          transition :example1, from: StateA, to: StateB
        end
      end

      context "when in a deadend state" do
        let(:initial_state) { "StateB" }

        it "does nothing" do
          expect { inst.example1 }
            .to_not change { inst.state.class }
        end
      end
    end
  end

  describe "fetching the current state" do
    let(:table) do
      proc do
        transition :example1, from: StateA, to: StateB
      end
    end

    context "when the current state class exists" do
      it "returns the state class" do
        expect(inst.state).to be_a(StateA)
      end
    end

    context "when the current state class doesn't exist" do
      let(:initial_state) { "DoesntExist" }

      it "raises an exception" do
        expect { inst.state }.to raise_error(StatefulModelRails::MissingStateDefinition)
      end
    end
  end
end
