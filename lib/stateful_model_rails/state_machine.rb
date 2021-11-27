# frozen_string_literal: true

module StatefulModelRails::StateMachine
  class State
    def before_leave(_); end

    def after_leave(_); end

    def before_enter(_); end

    def after_enter(_); end
  end

  class StateMachineInternal
    attr_reader :seen_states, :transition_map

    def initialize(field_name)
      @field_name = field_name
      @seen_states = []
      @transition_map = {}
    end

    def transition(event, from:, to:)
      @transition_map[event] ||= []
      @transition_map[event] << StatefulModelRails::Transition.new(from, to)

      @seen_states << from
      @seen_states << to
      @seen_states.uniq!
    end

    def install_event_helpers!(base)
      events = @transition_map.keys

      events.each do |event|
        fromtos = @transition_map[event]

        base.instance_eval do
          define_method(event) do
            matching_froms = fromtos.select { |fr| fr.from == state }

            raise TooManyDestinationStates if matching_froms.length > 1
            raise StatefulModelRails::NoMatchingTransition.new(state.name, event.to_s) if matching_froms.empty?

            matching_from = matching_froms[0]

            from_state = matching_from.from.new
            to_state = matching_from.to.new

            from_state.before_leave(self) if from_state.respond_to?(:before_leave)
            to_state.before_enter(self) if to_state.respond_to?(:before_enter)

            update!(state: matching_from.to.name)

            from_state.after_leave(self) if from_state.respond_to?(:after_leave)
            to_state.after_enter(self) if to_state.respond_to?(:after_enter)
          end
        end
      end
    end
  end

  def self.included(base)
    base.define_singleton_method(
      :state_machine,
      method(:included__state_machine)
    )

    base.define_method(
      :state,
      method(:included__state)
    )

    base.define_singleton_method(
      :state_machine_instance,
      method(:included__state_machine_instance)
    )
  end
end

def included__state_machine(opts, &block)
  field_name = opts.fetch(:on, "state")

  @state_machine = StatefulModelRails::StateMachine::StateMachineInternal.new(field_name)
  @state_machine.instance_eval(&block)
  @state_machine.install_event_helpers!(self)
  @state_machine
end

def included__state
  sm_instance = self.class.state_machine_instance
  st = sm_instance.seen_states.detect do |sf|
    sf.name == attributes["state"]
  end

  raise StatefulModelRails::MissingStateDefinition, attributes["state"] if st.nil?

  st
end

def included__state_machine_instance
  @state_machine
end
