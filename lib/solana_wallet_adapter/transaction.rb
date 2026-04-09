# frozen_string_literal: true
# typed: strict

module SolanaWalletAdapter
  # Mirrors the TransactionVersion type in @solana/web3.js.
  # Solana supports "legacy" transactions and versioned transactions (0+).
  class TransactionVersion < T::Enum
    enums do
      Legacy     = new("legacy")
      Version0   = new(0)
    end
  end

  # Mirrors SupportedTransactionVersions – a frozen set of accepted versions.
  # nil means "all versions supported" (equivalent to null/undefined in TS).
  SupportedTransactionVersions = T.type_alias { T.nilable(T::Set[TransactionVersion]) }

  # Lightweight wrapper around raw serialised Solana transaction bytes.
  # The gem does not attempt to parse the transaction wire format; that
  # responsibility belongs to a dedicated Solana RPC client gem.
  class Transaction
    extend T::Sig

    sig { returns(String) }
    attr_reader :wire_bytes

    sig { returns(T.nilable(TransactionVersion)) }
    attr_reader :version

    sig { params(wire_bytes: String, version: T.nilable(TransactionVersion)).void }
    def initialize(wire_bytes, version: nil)
      @wire_bytes = T.let(wire_bytes, String)
      @version    = T.let(version, T.nilable(TransactionVersion))
    end

    sig { returns(T::Boolean) }
    def versioned?
      !version.nil? && version != TransactionVersion::Legacy
    end

    sig { returns(String) }
    def serialize
      wire_bytes
    end
  end

  # Options forwarded to the RPC sendTransaction call.
  class SendTransactionOptions < T::Struct
    extend T::Sig

    # Additional signers that should co-sign the transaction before sending.
    const :signers,               T::Array[String],       default: []

    # Preflight commitment level.  Maps to Solana's Commitment type.
    const :preflight_commitment,  T.nilable(String),      default: nil

    # Whether to skip preflight simulation.
    const :skip_preflight,        T::Boolean,             default: false

    # Maximum number of retries.
    const :max_retries,           T.nilable(Integer),     default: nil

    # Minimum context slot for the transaction.
    const :min_context_slot,      T.nilable(Integer),     default: nil
  end
end
