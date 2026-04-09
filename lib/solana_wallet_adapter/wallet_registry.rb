# frozen_string_literal: true
# typed: strict

module SolanaWalletAdapter
  # A registry that maps wallet names to their adapter classes.
  # Provides a single place to look up all known wallet adapters and to
  # filter them by ready-state for use in frontend JSON serialisation.
  #
  # Usage:
  #   # Register your adapters (typically in an initializer)
  #   SolanaWalletAdapter::WalletRegistry.register(
  #     SolanaWalletAdapter::Wallets::PhantomWalletAdapter,
  #     SolanaWalletAdapter::Wallets::SolflareWalletAdapter,
  #   )
  #
  #   # Query
  #   WalletRegistry.all          # => [PhantomWalletAdapter, ...]
  #   WalletRegistry.find("Phantom") # => PhantomWalletAdapter
  class WalletRegistry
    extend T::Sig

    @adapters = T.let(
      {},
      T::Hash[String, T.class_of(BaseWalletAdapter)]
    )

    class << self
      extend T::Sig

      # Register one or more adapter classes.
      sig { params(adapter_classes: T::Array[T.class_of(BaseWalletAdapter)]).void }
      def register(*adapter_classes)
        adapter_classes.each do |klass|
          instance = klass.new
          @adapters[instance.name] = klass
        end
      end

      # Return all registered adapter classes in registration order.
      sig { returns(T::Array[T.class_of(BaseWalletAdapter)]) }
      def all
        @adapters.values
      end

      # Find an adapter class by wallet name.
      sig { params(name: String).returns(T.nilable(T.class_of(BaseWalletAdapter))) }
      def find(name)
        @adapters[name]
      end

      # Serialise all adapters to an array of hashes suitable for JSON.
      # Instantiates each adapter once to read metadata.
      sig { returns(T::Array[T::Hash[String, T.untyped]]) }
      def to_json_array
        @adapters.values.map { |klass| klass.new.to_h }
      end

      # Remove all registered adapters.  Useful in tests.
      sig { void }
      def reset!
        @adapters.clear
      end
    end
  end
end
