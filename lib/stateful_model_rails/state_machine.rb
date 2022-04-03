# frozen_string_literal: true

module StatefulModelRails::StateMachine
  class State
    class << self
      attr_reader :before_leave_callbacks, :after_leave_callbacks, :before_enter_callbacks, :after_enter_callbacks
    end

    attr_reader :parent

    def initialize(parent)
      @parent = parent
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

    def run_before_leave
      return unless self.class.before_leave_callbacks

      self.class.before_leave_callbacks.each { |b| b.call(self) }
    end

    def run_after_leave
      return unless self.class.after_leave_callbacks

      self.class.after_leave_callbacks.each { |b| b.call(self) }
    end

    def run_before_enter
      return unless self.class.before_enter_callbacks

      self.class.before_enter_callbacks.each { |b| b.call(self) }
    end

    def run_after_enter
      return unless self.class.after_enter_callbacks

      self.class.after_enter_callbacks.each { |b| b.call(self) }
    end

    def name
      self.class.name
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
      Array(from).each do |from|
        @transition_map[event] << StatefulModelRails::Transition.new(from, to)

        @seen_states << from
      end

      @seen_states << to
      @seen_states.uniq!
    end

    def install_event_helpers!(base)
      events = @transition_map.keys

      events.each do |event|
        fromtos = @transition_map[event]

        base.instance_eval do
          define_method(event) do
            with_lock do
              matching_froms = fromtos.select { |fr| fr.from == state.class }

              raise TooManyDestinationStates if matching_froms.length > 1
              raise StatefulModelRails::NoMatchingTransition.new(state.name, event.to_s) if matching_froms.empty?

              matching_from = matching_froms[0]

              from_state = matching_from.from.new(self)
              to_state = matching_from.to.new(self)

              from_state.run_before_leave if from_state.respond_to?(:run_before_leave)
              to_state.run_before_enter if to_state.respond_to?(:run_before_enter)

              update!(self.class.state_machine_instance.field_name.to_sym => matching_from.to.name)

              from_state.run_after_leave if from_state.respond_to?(:run_after_leave)
              to_state.run_after_enter if to_state.respond_to?(:run_after_enter)
            end
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
    sf.name.underscore == attributes[field_name].underscore
  end

  raise StatefulModelRails::MissingStateDefinition, attributes[field_name] if st.nil?

  st.new(self)
end

def included__state_machine_instance
  @state_machine
end
