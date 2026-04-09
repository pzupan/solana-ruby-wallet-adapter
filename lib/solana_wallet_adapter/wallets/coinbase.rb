# frozen_string_literal: true
# typed: strict

module SolanaWalletAdapter
  module Wallets
    class CoinbaseWalletAdapter < BaseMessageSignerWalletAdapter
      extend T::Sig

      COINBASE_ICON = T.let(
        "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAyNCIgaGVpZ2h0PSIxMDI0IiB2aWV3Qm94PSIwIDAgMTAyNCAxMDI0IiBm" \
        "aWxsPSJub25lIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgo8Y2lyY2xlIGN4PSI1MTIiIGN5" \
        "PSI1MTIiIHI9IjUxMiIgZmlsbD0iIzAwNTJGRiIvPgo8cGF0aCBmaWxsLXJ1bGU9ImV2ZW5vZGQiIGNsaXAtcnVs" \
        "ZT0iZXZlbm9kZCIgZD0iTTE1MiA1MTJDMTUyIDcxMC44MjMgMzEzLjE3NyA4NzIgNTEyIDg3MkM3MTAuODIzIDg3" \
        "MiA4NzIgNzEwLjgyMyA4NzIgNTEyQzg3MiAzMTMuMTc3IDcxMC44MjMgMTUyIDUxMiAxNTJDMzEzLjE3NyAxNTIg" \
        "MTUyIDMxMy4xNzcgMTUyIDUxMlpNNDIwIDM5NkM0MDYuNzQ1IDM5NiAzOTYgNDA2Ljc0NSAzOTYgNDIwVjYwNEMz" \
        "OTYgNjE3LjI1NSA0MDYuNzQ1IDYyOCA0MjAgNjI4SDYwNEM2MTcuMjU1IDYyOCA2MjggNjE3LjI1NSA2MjggNjA0" \
        "VjQyMEM2MjggNDA2Ljc0NSA2MTcuMjU1IDM5NiA2MDQgMzk2SDQyMFoiIGZpbGw9IndoaXRlIi8+Cjwvc3ZnPgo=",
        String
      )

      sig { override.returns(String) }
      def name = "Coinbase Wallet"

      sig { override.returns(String) }
      def url = "https://chrome.google.com/webstore/detail/coinbase-wallet-extension/hnfanknocfeofbddgcijnmhnfnkdnaad"

      sig { override.returns(String) }
      def icon = COINBASE_ICON

      sig { override.returns(WalletReadyState) }
      def ready_state = WalletReadyState::Unsupported

      sig { override.returns(T.nilable(PublicKey)) }
      def public_key = nil

      sig { override.returns(T::Boolean) }
      def connecting? = false

      sig { override.returns(SupportedTransactionVersions) }
      def supported_transaction_versions
        Set[TransactionVersion::Legacy, TransactionVersion::Version0].freeze
      end

      sig { override.void }
      def connect
        raise WalletNotReadyError, "#{name} connection is initiated in the browser"
      end

      sig { override.void }
      def disconnect; end

      sig do
        override
          .params(transaction: Transaction, rpc_url: String, options: SendTransactionOptions)
          .returns(String)
      end
      def send_transaction(transaction, rpc_url, options = SendTransactionOptions.new)
        raise WalletNotConnectedError, "send_transaction must use a pre-signed transaction server-side"
      end

      sig { override.params(transaction: Transaction).returns(Transaction) }
      def sign_transaction(transaction)
        raise WalletNotConnectedError, "sign_transaction must be performed client-side"
      end

      sig { override.params(transactions: T::Array[Transaction]).returns(T::Array[Transaction]) }
      def sign_all_transactions(transactions)
        raise WalletNotConnectedError, "sign_all_transactions must be performed client-side"
      end

      sig { override.params(message: String).returns(String) }
      def sign_message(message)
        raise WalletNotConnectedError, "sign_message must be performed client-side"
      end
    end
  end
end
