# frozen_string_literal: true
# typed: strict

module SolanaWalletAdapter
  # Abstract base class for all wallet adapters.
  # Mirrors BaseWalletAdapter from @solana/wallet-adapter-base.
  #
  # Subclasses MUST implement:
  #   - name        (String)
  #   - url         (String)
  #   - icon        (String)
  #   - ready_state (WalletReadyState)
  #   - public_key  (T.nilable(PublicKey))
  #   - connecting? (Boolean)
  #   - connect
  #   - disconnect
  #   - send_transaction(transaction, rpc_url, options)
  #
  # In Rails the adapter is used server-side to:
  #   1. Supply wallet metadata (name/icon/url) for the frontend.
  #   2. Verify signatures returned by the front-end wallet.
  #   3. Facilitate Sign-In-With-Solana flows.
  class BaseWalletAdapter
    extend  T::Sig
    extend  T::Helpers
    include EventEmitter

    abstract!

    # -------------------------------------------------------------------------
    # Abstract interface
    # -------------------------------------------------------------------------

    # Human-readable wallet name.
    sig { abstract.returns(String) }
    def name; end

    # URL pointing to the wallet's download / landing page.
    sig { abstract.returns(String) }
    def url; end

    # Base64-encoded SVG or PNG data URI for the wallet's icon.
    sig { abstract.returns(String) }
    def icon; end

    # Current ready state of this adapter.
    sig { abstract.returns(WalletReadyState) }
    def ready_state; end

    # The currently connected public key, or nil when not connected.
    sig { abstract.returns(T.nilable(PublicKey)) }
    def public_key; end

    # True while a connection is in progress.
    sig { abstract.returns(T::Boolean) }
    def connecting?; end

    # Set of supported transaction versions. nil means all versions.
    sig { returns(SupportedTransactionVersions) }
    def supported_transaction_versions
      nil
    end

    # Initiate a wallet connection.
    sig { abstract.void }
    def connect; end

    # Disconnect the wallet.
    sig { abstract.void }
    def disconnect; end

    # Send a transaction to the network via the RPC endpoint.
    sig do
      abstract
        .params(
          transaction: Transaction,
          rpc_url:     String,
          options:     SendTransactionOptions
        )
        .returns(String) # transaction signature (base58)
    end
    def send_transaction(transaction, rpc_url, options); end

    # -------------------------------------------------------------------------
    # Concrete helpers
    # -------------------------------------------------------------------------

    # True when a public key is present (i.e. connected).
    sig { returns(T::Boolean) }
    def connected?
      !public_key.nil?
    end

    # Serialize adapter metadata as a plain Hash (useful for JSON APIs).
    sig { returns(T::Hash[String, T.untyped]) }
    def to_h
      {
        "name"        => name,
        "url"         => url,
        "icon"        => icon,
        "readyState"  => ready_state.serialize,
        "connected"   => connected?,
        "publicKey"   => public_key&.to_base58,
      }
    end

    sig { returns(String) }
    def inspect
      "#<#{self.class} name=#{name.inspect} ready_state=#{ready_state.serialize}>"
    end
  end
end
