# frozen_string_literal: true

require "stateful_model_rails"

RSpec.describe StatefulModelRails::StateMachine do
  describe "state derivation" do
    context "without configuring the `on` field" do
      def effective_class
        Class.new do
          include StatefulModelRails::StateMachine

          state_machine do
            transition :void, from: StateA, to: StateA
          end
        end
      end

      let(:instance) { effective_class.new }

      it "derives from `state`" do
        instance = effective_class.new
        allow(instance).to receive(:attributes).and_return({ "state" => "StateA" })

        expect(instance.state).to eq(StateA)
      end
    end

    context "when configuring the `on` field" do
      def effective_class
        Class.new do
          include StatefulModelRails::StateMachine

          state_machine(on: :other_field) do
            transition :void, from: StateA, to: StateA
          end
        end
      end

      let(:instance) { effective_class.new }

      it "derives from the declared field" do
        instance = effective_class.new
        allow(instance).to receive(:attributes).and_return({ "other_field" => "StateA" })

        expect(instance.state).to eq(StateA)
      end
    end
  end
end
