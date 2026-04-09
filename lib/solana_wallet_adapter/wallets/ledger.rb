# frozen_string_literal: true
# typed: strict

module SolanaWalletAdapter
  module Wallets
    class LedgerWalletAdapter < BaseSignerWalletAdapter
      extend T::Sig

      LEDGER_ICON = T.let(
        "data:image/svg+xml;base64,PHN2ZyB2aWV3Qm94PSIwIDAgMzUgMzUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2Zy" \
        "I+PGcgZmlsbD0iI2ZmZiI+PHBhdGggZD0ibTIzLjU4OCAweC0xNnYyMS41ODNoMjEuNnYtMTZhNS41ODUgNS41OD" \
        "UgMCAwIDAgLTUuNi01LjU4M3oiIHRyYW5zZm9ybT0idHJhbnNsYXRlKDUuNzM5KSIvPjxwYXRoIGQ9Im04LjM0Mi" \
        "AwaC0yLjc1N2E1LjU4NSA1LjU4NSAwIDAgMCAtNS41ODUgNS41ODV2Mi43NTdoOC4zNDJ6Ii8+PHBhdGggZD0ibTAg" \
        "Ny41OWg4LjM0MnY4LjM0MmgtOC4zNDJ6IiB0cmFuc2Zvcm09InRyYW5zbGF0ZSgwIDUuNzM5KSIvPjxwYXRoIGQ9" \
        "Im0xNS4xOCAyMy40NTFoMi43NTdhNS41ODUgNS41ODUgMCAwIDAgNS41ODUtNS42di0yLjY3MWgtOC4zNDJ6IiB0" \
        "cmFuc2Zvcm09InRyYW5zbGF0ZSgxMS40NzggMTEuNDc4KSIvPjxwYXRoIGQ9Im03LjU5IDE1LjE4aDguMzQydjgu" \
        "MzQyaC04LjM0MnoiIHRyYW5zZm9ybT0idHJhbnNsYXRlKDUuNzM5IDExLjQ3OCkiLz48cGF0aCBkPSJtMCAxNS4x" \
        "OHYyLjc1N2E1LjU4NSA1LjU4NSAwIDAgMCA1LjU4NSA1LjU4NWgyLjc1N3YtOC4zNDJ6IiB0cmFuc2Zvcm09InRy" \
        "YW5zbGF0ZSgwIDExLjQ3OCkiLz48L2c+PC9zdmc+",
        String
      )

      sig { override.returns(String) }
      def name = "Ledger"

      sig { override.returns(String) }
      def url = "https://ledger.com"

      sig { override.returns(String) }
      def icon = LEDGER_ICON

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
        raise WalletNotReadyError, "#{name} connection is initiated in the browser via USB/Bluetooth"
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
        raise WalletNotConnectedError, "sign_transaction must be performed client-side by the Ledger device"
      end

      sig { override.params(transactions: T::Array[Transaction]).returns(T::Array[Transaction]) }
      def sign_all_transactions(transactions)
        raise WalletNotConnectedError, "sign_all_transactions must be performed client-side"
      end
    end
  end
end
