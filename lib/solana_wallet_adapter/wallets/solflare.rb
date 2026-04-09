# frozen_string_literal: true
# typed: strict

module SolanaWalletAdapter
  module Wallets
    class SolflareWalletAdapter < BaseMessageSignerWalletAdapter
      extend T::Sig

      SOLFLARE_ICON = T.let(
        "data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz48c3ZnIGlkPSJTIiB4bWxucz0i" \
        "aHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA1MCA1MCI+PGRlZnM+PHN0eWxlPi5jbHMt" \
        "MXtmaWxsOiMwMjA1MGE7c3Ryb2tlOiNmZmVmNDY7c3Ryb2tlLW1pdGVybGltaXQ6MTA7c3Ryb2tlLXdpZHRoOi41" \
        "cHg7fS5jbHMtMntmaWxsOiNmZmVmNDY7fTwvc3R5bGU+PC9kZWZzPjxyZWN0IGNsYXNzPSJjbHMtMiIgeD0iMCIg" \
        "d2lkdGg9IjUwIiBoZWlnaHQ9IjUwIiByeD0iMTIiIHJ5PSIxMiIvPjxwYXRoIGNsYXNzPSJjbHMtMSIgZD0iTTI0" \
        "LjIzLDI2LjQybDIuNDYtMi4zOCw0LjU5LDEuNWMzLjAxLDEsNC41MSwyLjg0LDQuNTEsNS40MywwLDEuOTYtLjc1" \
        "LDMuMjYtMi4yNSw0LjkzbC0uNDYuNS4xNy0xLjE3Yy42Ny00LjI2LS41OC02LjA5LTQuNzItNy40M2wtNC4zLTEu" \
        "MzhoMFpNMTguMDUsMTEuODVsMTIuNTIsNC4xNy0yLjcxLDIuNTktNi41MS0yLjE3Yy0yLjI1LS43NS0zLjAxLTEu" \
        "OTYtMy4zLTQuNTF2LS4wOGgwWk0xNy4zLDMzLjA2bDIuODQtMi43MSw1LjM0LDEuNzVjMi44LjkyLDMuNzYsMi4x" \
        "MywzLjQ2LDUuMThsLTExLjY1LTQuMjJoMFpNMTMuNzEsMjAuOTVjMC0uNzkuNDItMS41NCwxLjEzLTIuMTcuNzUs" \
        "MS4wOSwyLjA1LDIuMDUsNC4wOSwyLjcxbDQuNDIsMS40Ni0yLjQ2LDIuMzgtNC4zNC0xLjQyYy0yLS42Ny0yLjg0" \
        "LTEuNjctMi44NC0yLjk2TTI2LjgyLDQyLjg3YzkuMTgtNi4wOSwxNC4xMS0xMC4yMywxNC4xMS0xNS4zMiwwLTMu" \
        "MzgtMi01LjI2LTYuNDMtNi43MmwtMy4zNC0xLjEzLDkuMTQtOC43Ny0xLjg0LTEuOTYtMi43MSwyLjM4LTEyLjgx" \
        "LTQuMjJjLTMuOTcsMS4yOS04Ljk3LDUuMDktOC45Nyw4Ljg5LDAsLjQyLjA0LjgzLjE3LDEuMjktMy4zLDEuODgt" \
        "NC42MywzLjYzLTQuNjMsNS44LDAsMi4wNSwxLjA5LDQuMDksNC41NSw1LjIybDIuNzUuOTItOS41Miw5LjE0LDEu" \
        "ODQsMS45NiwyLjk2LTIuNzEsMTQuNzMsNS4yMmgwWiIvPjwvc3ZnPg==",
        String
      )

      sig { override.returns(String) }
      def name = "Solflare"

      sig { override.returns(String) }
      def url = "https://solflare.com"

      sig { override.returns(String) }
      def icon = SOLFLARE_ICON

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
