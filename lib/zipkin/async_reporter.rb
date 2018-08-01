# frozen_string_literal: true

require 'thread'

require_relative './async_reporter/buffer'

module Zipkin
  class AsyncReporter
    def self.create(sender:, flush_interval:)
      reporter = new(sender)

      # start flush thread
      Thread.new do
        loop do
          reporter.flush
          sleep(flush_interval)
        end
      end

      reporter
    end

    def initialize(sender)
      @sender = sender
      @buffer = Buffer.new
    end

    def flush
      spans = @buffer.retrieve
      @sender.send_spans(spans) if spans.any?
      spans
    end

    def report(span)
      return unless span.context.sampled?
      @buffer << span
    end
  end
end
