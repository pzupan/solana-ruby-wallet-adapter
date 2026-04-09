# frozen_string_literal: true
# typed: strict

module SolanaWalletAdapter
  # A simple synchronous event-emitter mixin.
  # Mirrors the EventEmitter3 interface used by the TypeScript adapters.
  #
  # Usage:
  #   class MyAdapter
  #     include EventEmitter
  #     # ...
  #     def do_something
  #       emit(:connect, public_key)
  #     end
  #   end
  #
  #   adapter = MyAdapter.new
  #   adapter.on(:connect) { |pk| puts "connected: #{pk}" }
  module EventEmitter
    extend T::Sig
    extend T::Helpers

    # @!visibility private
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      extend T::Sig
    end

    # Register a listener for the given event name.
    # Returns self for chaining.
    sig { params(event: Symbol, block: T.proc.params(args: T.untyped).void).returns(T.self_type) }
    def on(event, &block)
      listeners_for(event) << block
      self
    end

    # Register a one-shot listener that auto-removes itself after the first call.
    sig { params(event: Symbol, block: T.proc.params(args: T.untyped).void).returns(T.self_type) }
    def once(event, &block)
      wrapper = T.let(nil, T.nilable(Proc))
      wrapper = proc do |*args|
        off(event, T.must(wrapper))
        block.call(*args)
      end
      on(event, &T.must(wrapper))
      self
    end

    # Remove a specific listener (or all listeners if block is omitted).
    sig { params(event: Symbol, block: T.nilable(Proc)).returns(T.self_type) }
    def off(event, block = nil)
      if block
        listeners_for(event).delete(block)
      else
        event_listeners.delete(event)
      end
      self
    end

    # Emit an event, calling all registered listeners synchronously.
    sig { params(event: Symbol, args: T.untyped).void }
    def emit(event, *args)
      listeners_for(event).dup.each { |listener| listener.call(*args) }
    end

    private

    sig { params(event: Symbol).returns(T::Array[Proc]) }
    def listeners_for(event)
      event_listeners[event] ||= []
    end

    sig { returns(T::Hash[Symbol, T::Array[Proc]]) }
    def event_listeners
      @event_listeners ||= T.let({}, T.nilable(T::Hash[Symbol, T::Array[Proc]]))
      T.must(@event_listeners)
    end
  end
end
