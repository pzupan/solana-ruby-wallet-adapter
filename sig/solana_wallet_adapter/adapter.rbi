# typed: true

module SolanaWalletAdapter
  class BaseWalletAdapter
    include EventEmitter

    sig { abstract.returns(String) }
    def name; end

    sig { abstract.returns(String) }
    def url; end

    sig { abstract.returns(String) }
    def icon; end

    sig { abstract.returns(WalletReadyState) }
    def ready_state; end

    sig { abstract.returns(T.nilable(PublicKey)) }
    def public_key; end

    sig { abstract.returns(T::Boolean) }
    def connecting?; end

    sig { returns(SupportedTransactionVersions) }
    def supported_transaction_versions; end

    sig { abstract.void }
    def connect; end

    sig { abstract.void }
    def disconnect; end

    sig do
      abstract
        .params(transaction: Transaction, rpc_url: String, options: SendTransactionOptions)
        .returns(String)
    end
    def send_transaction(transaction, rpc_url, options); end

    sig { returns(T::Boolean) }
    def connected?; end

    sig { returns(T::Hash[String, T.untyped]) }
    def to_h; end
  end
end
