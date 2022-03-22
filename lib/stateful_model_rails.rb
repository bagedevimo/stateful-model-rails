# frozen_string_literal: true

require "stateful_model_rails/version"
require "stateful_model_rails/state_machine"
require "stateful_model_rails/transition"

require "active_support/core_ext/string/inflections"

module StatefulModelRails
  class Error < StandardError; end

  class MissingStateDefinition < Error
    def initialize(missing_class_name)
      @missing_class_name = missing_class_name

      super()
    end

    def to_s
      "Couldn't find class definition for state named #{@missing_class_name}"
    end
  end

  class NoMatchingTransition < Error
    def initialize(current_state, triggering_event)
      @current_state = current_state
      @triggering_event = triggering_event

      super()
    end

    def to_s
      "There is no event #{@triggering_event} from #{@current_state}"
    end
  end

  class DirtyModel < Error
    def to_s
      "There are unsaved changes to this record that would be override by doing a state machine transition"
    end
  end
end
