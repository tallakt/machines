include 'ruby-plc/sequences/step_base'
include 'ruby-plc/timedomain/sequencer'

module RubyPlc
  module Sequences
    class Step
      include StepBase

      attr_reader :name

      def initialize(name = nil)
        @name = name
        yield self if block_given?
      end

      def perform_start
        @active = true
      end

      def perform_finish
        @active = false
      end
      
      def perform_reset
        perform_finish
      end

      def active?
        @active
      end
    end
  end
end


