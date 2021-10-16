# frozen_string_literal: true

require "stateful_model_rails"
require "spec_helper"

RSpec.describe StatefulModelRails::StateMachine do
  let(:smi) { classdef(table).state_machine_instance }

  def classdef(block)
    Class.new do
      include StatefulModelRails::StateMachine

      state_machine(on: :state, &block)
    end
  end

  describe "graph construction" do
    let(:graph) { smi.transition_map }

    context "with no transitions" do
      let(:table) { proc {} }

      it "returns an empty transitions table" do
        expect(graph).to be_empty
      end
    end

    context "with one transition" do
      let(:table) do
        proc do
          transition :example1, from: StateA, to: StateB
        end
      end

      it "returns a transition table with the one event" do
        expect(graph.length).to eq(1)
        expect(graph.values.first.length).to eq(1)
      end
    end

    context "with two transitions, both seperate events" do
      let(:table) do
        proc do
          transition :example1, from: StateA, to: StateB
          transition :example2, from: StateA, to: StateB
        end
      end

      it "returns a transition table with the one event" do
        expect(graph.length).to eq(2)

        expect(graph[:example1]).to match_array(
          [
            StatefulModelRails::Transition.new(StateA, StateB)
          ]
        )

        expect(graph[:example2]).to match_array(
          [
            StatefulModelRails::Transition.new(StateA, StateB)
          ]
        )
      end
    end

    context "with two transitions, both same event diferent sources" do
      let(:table) do
        proc do
          transition :example1, from: StateA, to: StateB
          transition :example1, from: StateC, to: StateB
        end
      end

      it "returns a transition table with the one event" do
        expect(graph.keys).to match_array([:example1])

        expect(graph[:example1]).to match_array(
          [
            StatefulModelRails::Transition.new(StateA, StateB),
            StatefulModelRails::Transition.new(StateC, StateB)
          ]
        )
      end
    end

    context "with two transitions, same events different states, looped" do
      let(:table) do
        proc do
          transition :example1, from: StateA, to: StateB
          transition :example1, from: StateB, to: StateA
        end
      end

      it "returns a transition table with the one event" do
        expect(graph.keys).to match_array([:example1])

        expect(graph[:example1]).to match_array(
          [
            StatefulModelRails::Transition.new(StateA, StateB),
            StatefulModelRails::Transition.new(StateB, StateA)
          ]
        )
      end
    end
  end
end
