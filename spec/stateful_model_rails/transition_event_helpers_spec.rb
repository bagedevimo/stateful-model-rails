# frozen_string_literal: true

require "spec_helper"
require "stateful_model_rails"

RSpec.describe StatefulModelRails::StateMachine do
  let(:smi) { classdef.state_machine_instance }
  let(:classdef) { build_classdef(table) }
  let(:event_methods) do
    classdef.new.methods -
      Class.methods -
      [:state_machine_instance, :state, :state_machine]
  end

  def build_classdef(block)
    Class.new do
      include StatefulModelRails::StateMachine

      state_machine(on: :state, &block)
    end
  end

  describe "transition event helpers" do
    context "with no transitions" do
      let(:table) { proc {} }

      it "doesn't need to add any special event methods" do
        expect(event_methods).to be_empty
      end
    end

    context "with one transition" do
      let(:table) do
        proc do
          transition :example1, from: StateA, to: StateB
        end
      end

      it "adds methods for all unique events" do
        expect(event_methods).to match_array([:example1])
      end
    end

    context "with two transitions, both seperate events" do
      let(:table) do
        proc do
          transition :example1, from: StateA, to: StateB
          transition :example2, from: StateA, to: StateB
        end
      end

      it "adds methods for all unique events" do
        expect(event_methods).to match_array([:example1, :example2])
      end
    end

    context "with two transitions, both same event diferent sources" do
      let(:table) do
        proc do
          transition :example1, from: StateA, to: StateB
          transition :example1, from: StateC, to: StateB
        end
      end

      it "adds methods for all unique events" do
        expect(event_methods).to match_array([:example1])
      end
    end

    context "with two transitions, same events different states, looped" do
      let(:table) do
        proc do
          transition :example1, from: StateA, to: StateB
          transition :example1, from: StateB, to: StateA
        end
      end

      it "adds methods for all unique events" do
        expect(event_methods).to match_array([:example1])
      end
    end
  end
end
