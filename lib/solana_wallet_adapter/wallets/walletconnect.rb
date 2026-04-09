# frozen_string_literal: true
# typed: strict

module SolanaWalletAdapter
  module Wallets
    # WalletConnect adapter – connects via QR-code/deep-link protocol.
    class WalletConnectWalletAdapter < BaseMessageSignerWalletAdapter
      extend T::Sig

      WALLETCONNECT_ICON = T.let(
        "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzAwIiBoZWlnaHQ9IjE4NSIgdmlld0JveD0iMCAwIDMwMCAxODUiIHhtbG5z" \
        "PSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHBhdGggZD0iTTYxLjQzODUgMzYuMjU2MkMxMDkuMzQ4IC0x" \
        "Mi4wODU0IDE4Ny4xNjkgLTEyLjA4NTQgMjM1LjA3OCAzNi4yNTYyTDI0MC44ODEgNDIuMTEyN0MyNDMuNDM2IDQ0" \
        "LjY5MDcgMjQzLjQzNiA0OC44NjkzIDI0MC44ODEgNTEuNDQ3M0wyMjAuOTg3IDcxLjQ4NTVDMjE5LjcwOSA3Mi43" \
        "NzQ1IDIxNy42NDQgNzIuNzc0NSAyMTYuMzY2IDcxLjQ4NTVMMjA4LjA2MSA2My4xMjg1QzE3NS40MDkgMzAuMzMw" \
        "MyAxMjEuMTA4IDMwLjMzMDMgODguNDU2IDYzLjEyODVMNzkuNTc3IDcyLjA2NzFDNzguMjk5IDczLjM1NjEgNzYu" \
        "MjMzOSA3My4zNTYxIDc0Ljk1NTkgNzIuMDY3MUw1NS4wNjIyIDUyLjAyODhDNTIuNTA3MyA0OS40NTA4IDUyLjUw" \
        "NzMgNDUuMjcyMiA1NS4wNjIyIDQyLjY5NDJMNjEuNDM4NSAzNi4yNTYyWk0yNzYuNDQ3IDc3Ljk3NzJMMjk0LjIg" \
        "OTUuODQ5MkMyOTYuNzU1IDk4LjQyNzIgMjk2Ljc1NSAxMDIuNjA2IDI5NC4yIDEwNS4xODRMMjEyLjE0NiAxODcu" \
        "Njg5QzIwOS41OTEgMTkwLjI2NyAyMDUuNDYgMTkwLjI2NyAyMDIuOTA1IDE4Ny42ODlMMTQzLjIxMiAxMjcuODI2" \
        "QzE0Mi41NzMgMTI3LjE4MiAxNDEuNTQgMTI3LjE4MiAxNDAuOTAxIDEyNy44MjZMODEuMjA4NiAxODcuNjg5Qzc4" \
        "LjY1MzcgMTkwLjI2NyA3NC41MjMzIDE5MC4yNjcgNzEuOTY4NCAxODcuNjg5TDkuODU2NjkgMTA1LjE4NEM3LjMw" \
        "MTc2IDEwMi42MDYgNy4zMDE3NiA5OC40MjcyIDkuODU2NjkgOTUuODQ5MkwyNy42MDUxIDc3Ljk3NzJDMzAuMTYg" \
        "NzUuMzk5MiAzNC4yOTA0IDc1LjM5OTIgMzYuODQ1MyA3Ny45NzcyTDk2LjUzODUgMTM3Ljg0Qzk3LjE3NzMgMTM4" \
        "LjQ4NCA5OC4yMTA2IDEzOC40ODQgOTguODQ5NCAxMzcuODRMMTU4LjU0MiA3Ny45NzcyQzE2MS4wOTcgNzUuMzk5" \
        "MiAxNjUuMjI3IDc1LjM5OTIgMTY3Ljc4MiA3Ny45NzcyTDIyNy40NzUgMTM3Ljg0QzIyOC4xMTQgMTM4LjQ4NCAy" \
        "MjkuMTQ3IDEzOC40ODQgMjI5Ljc4NiAxMzcuODRMMjg5LjQ3OSA3Ny45NzcyQzI5Mi4wMzQgNzUuMzk5MiAyOTYu" \
        "MTY0IDc1LjM5OTIgMjk4LjcxOSA3Ny45NzcyWiIgZmlsbD0iIzM0OTZGRiIvPjwvc3ZnPg==",
        String
      )

      sig { override.returns(String) }
      def name = "WalletConnect"

      sig { override.returns(String) }
      def url = "https://walletconnect.com"

      sig { override.returns(String) }
      def icon = WALLETCONNECT_ICON

      sig { override.returns(WalletReadyState) }
      def ready_state = WalletReadyState::Loadable

      sig { override.returns(T.nilable(PublicKey)) }
      def public_key = nil

      sig { override.returns(T::Boolean) }
      def connecting? = false

      sig { override.returns(SupportedTransactionVersions) }
      def supported_transaction_versions
        Set[TransactionVersion::Legacy].freeze
      end

      sig { override.void }
      def connect
        raise WalletNotReadyError, "#{name} connection is initiated in the browser via QR code"
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
