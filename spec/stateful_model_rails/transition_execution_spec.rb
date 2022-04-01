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

  context "with one transition" do
    let(:table) do
      proc do
        transition :example1, from: StateA, to: StateB
      end
    end

    context "when in the initial default state" do
      it "transitions" do
        expect { inst.example1 }
          .to change { inst.state }
          .from(StateA)
          .to(StateB)
      end
    end

    context "when in a deadend state" do
      let(:initial_state) { "StateB" }

      it "raises no existing transition" do
        expect { inst.example1 }
          .to raise_error(StatefulModelRails::NoMatchingTransition)
      end
    end
  end

  context "with a configured `field_name`" do
    def build_classdef(block)
      Class.new do
        def initialize(initial_state)
          @field_name = initial_state
        end

        def update!(field_name:)
          @field_name = field_name
        end

        def with_lock
          yield if block_given?
        end

        def attributes
          { "field_name" => @field_name }
        end

        include StatefulModelRails::StateMachine

        state_machine(on: :field_name, &block)
      end
    end

    let(:table) do
      proc do
        transition :example1, from: StateA, to: StateB
      end
    end

    context "when in the initial default state" do
      it "transitions" do
        expect { inst.example1 }
          .to change { inst.state }
          .from(StateA)
          .to(StateB)
      end
    end
  end

  context "with two transitions, both seperate events, same src & dst" do
    let(:table) do
      proc do
        transition :example1, from: StateA, to: StateB
        transition :example2, from: StateA, to: StateB
      end
    end

    it "transitions with example1" do
      expect { inst.example1 }
        .to change { inst.state }
        .from(StateA)
        .to(StateB)
    end

    it "transitions with example2" do
      expect { inst.example2 }
        .to change { inst.state }
        .from(StateA)
        .to(StateB)
    end
  end

  context "with two transitions, both same event diferent sources" do
    let(:table) do
      proc do
        transition :example1, from: StateA, to: StateB
        transition :example1, from: StateC, to: StateB
      end
    end

    context "when in A, receiving example1" do
      let(:initial_state) { "StateA" }

      it "transitions" do
        expect { inst.example1 }
          .to change { inst.state }
          .from(StateA)
          .to(StateB)
      end
    end

    context "when in B, receiving example1" do
      let(:initial_state) { "StateB" }

      it "raises an error" do
        expect { inst.example1 }
          .to raise_error(StatefulModelRails::NoMatchingTransition)
      end
    end

    context "when in C, receiving example1" do
      let(:initial_state) { "StateC" }

      it "transitions" do
        expect { inst.example1 }
          .to change { inst.state }
          .from(StateC)
          .to(StateB)
      end
    end
  end

  context "with two transitions, same events different states, looped" do
    let(:table) do
      proc do
        transition :example1, from: StateA, to: StateB
        transition :example1, from: StateB, to: StateA
      end
    end

    context "when starting in the first state" do
      it "transitions, multiple times" do
        expect { inst.example1 }
          .to change { inst.state }
          .from(StateA)
          .to(StateB)

        expect { inst.example1 }
          .to change { inst.state }
          .from(StateB)
          .to(StateA)
      end
    end

    context "when starting in the second state" do
      let(:initial_state) { "StateB" }

      it "transitions, multiple times" do
        expect { inst.example1 }
          .to change { inst.state }
          .from(StateB)
          .to(StateA)

        expect { inst.example1 }
          .to change { inst.state }
          .from(StateA)
          .to(StateB)
      end
    end
  end
end
