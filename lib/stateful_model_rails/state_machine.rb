# frozen_string_literal: true

module StatefulModelRails::StateMachine
  class State
    class << self
      attr_reader :before_leave_callbacks, :after_leave_callbacks, :before_enter_callbacks, :after_enter_callbacks
    end

    def self.before_leave(&block)
      @before_leave_callbacks ||= []
      @before_leave_callbacks << block
    end

    def self.after_leave(&block)
      @after_leave_callbacks ||= []
      @after_leave_callbacks << block
    end

    def self.before_enter(&block)
      @before_enter_callbacks ||= []
      @before_enter_callbacks << block
    end

    def self.after_enter(&block)
      @after_enter_callbacks ||= []
      @after_enter_callbacks << block
    end

    def run_before_leave(args)
      return unless self.class.before_leave_callbacks

      self.class.before_leave_callbacks.each { |b| b.call(args) }
    end

    def run_after_leave(args)
      return unless self.class.after_leave_callbacks

      self.class.after_leave_callbacks.each { |b| b.call(args) }
    end

    def run_before_enter(args)
      return unless self.class.before_enter_callbacks

      self.class.before_enter_callbacks.each { |b| b.call(args) }
    end

    def run_after_enter(args)
      return unless self.class.after_enter_callbacks

      self.class.after_enter_callbacks.each { |b| b.call(args) }
    end
  end

  class StateMachineInternal
    attr_reader :seen_states, :transition_map, :field_name

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

            from_state.run_before_leave(self) if from_state.respond_to?(:run_before_leave)
            to_state.run_before_enter(self) if to_state.respond_to?(:run_before_enter)

            update!(state: matching_from.to.name)

            from_state.run_after_leave(self) if from_state.respond_to?(:run_after_leave)
            to_state.run_after_enter(self) if to_state.respond_to?(:run_after_enter)
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

def included__state_machine(opts = {}, &block)
  field_name = opts.fetch(:on, "state").to_s

  @state_machine = StatefulModelRails::StateMachine::StateMachineInternal.new(field_name)
  @state_machine.instance_eval(&block)
  @state_machine.install_event_helpers!(self)
  @state_machine
end

def included__state
  sm_instance = self.class.state_machine_instance
  field_name = sm_instance.field_name

  st = sm_instance.seen_states.detect do |sf|
    sf.name == attributes[field_name]
  end

  raise StatefulModelRails::MissingStateDefinition, attributes[field_name] if st.nil?

  st
end

def included__state_machine_instance
  @state_machine
end
