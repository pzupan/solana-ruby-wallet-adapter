# frozen_string_literal: true
# typed: strict

module SolanaWalletAdapter
  module Wallets
    # Server-side metadata adapter for the Phantom wallet.
    #
    # In a Rails app the "connecting" lifecycle is handled in the browser by
    # the Phantom extension / app.  This class provides:
    #   - Wallet metadata (name, icon, url) for frontend consumption.
    #   - A stub implementation of the abstract interface so instances can be
    #     registered in WalletRegistry and serialised to JSON.
    #   - Optional override points for custom server-side send_transaction /
    #     sign_message if you choose to proxy those calls through the server.
    #
    # For a full round-trip flow:
    #   1. Render wallet metadata to the frontend via WalletRegistry.to_json_array.
    #   2. The browser connects to Phantom and obtains a public key + signature.
    #   3. POST both to a Rails controller.
    #   4. Verify server-side with SignatureVerifier.
    class PhantomWalletAdapter < BaseMessageSignerWalletAdapter
      extend T::Sig

      PHANTOM_ICON = T.let(
        "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDgi" \
        "IGhlaWdodD0iMTA4IiB2aWV3Qm94PSIwIDAgMTA4IDEwOCIgZmlsbD0ibm9uZSI+CjxyZWN0IHdpZHRoPSIxMDgi" \
        "IGhlaWdodD0iMTA4IiByeD0iMjYiIGZpbGw9IiNBQjlGRjIiLz4KPHBhdGggZmlsbC1ydWxlPSJldmVub2RkIiBj" \
        "bGlwLXJ1bGU9ImV2ZW5vZGQiIGQ9Ik00Ni41MjY3IDY5LjkyMjlDNDIuMDA1NCA3Ni44NTA5IDM0LjQyOTIgODUu" \
        "NjE4MiAyNC4zNDggODUuNjE4MkMxOS41ODI0IDg1LjYxODIgMTUgODMuNjU2MyAxNSA3NS4xMzQyQzE1IDUzLjQz" \
        "MDUgNDQuNjMyNiAxOS44MzI3IDcyLjEyNjggMTkuODMyN0M4Ny43NjggMTkuODMyNyA5NCAzMC42ODQ2IDk0IDQz" \
        "LjAwNzlDOTQgNTguODI1OCA4My43MzU1IDc2LjkxMjIgNzMuNTMyMSA3Ni45MTIyQzcwLjI5MzkgNzYuOTEyMiA2" \
        "OC43MDUzIDc1LjEzNDIgNjguNzA1MyA3Mi4zMTRDNjguNzA1MyA3MS41NzgzIDY4LjgyNzUgNzAuNzgxMiA2OS4w" \
        "NzE5IDY5LjkyMjlDNjUuNTg5MyA3NS44Njk5IDU4Ljg2ODUgODEuMzg3OCA1Mi41NzU0IDgxLjM4NzhDNDcuOTkz" \
        "IDgxLjM4NzggNDUuNjcxMyA3OC41MDYzIDQ1LjY3MTMgNzQuNDU5OEM0NS42NzEzIDcyLjk4ODQgNDUuOTc2OCA3" \
        "MS40NTU2IDQ2LjUyNjcgNjkuOTIyOVpNODMuNjc2MSA0Mi41Nzk0QzgzLjY3NjEgNDYuMTcwNCA4MS41NTc1IDQ3" \
        "Ljk2NTggNzkuMTg3NSA0Ny45NjU4Qzc2Ljc4MTYgNDcuOTY1OCA3NC42OTg5IDQ2LjE3MDQgNzQuNjk4OSA0Mi41" \
        "Nzk0Qzc0LjY5ODkgMzguOTg4NSA3Ni43ODE2IDM3LjE5MzEgNzkuMTg3NSAzNy4xOTMxQzgxLjU1NzUgMzcuMTkz" \
        "MSA4My42NzYxIDM4Ljk4ODUgODMuNjc2MSA0Mi41Nzk0Wk03MC4yMTAzIDQyLjU3OTVDNzAuMjEwMyA0Ni4xNzA0" \
        "IDY4LjA5MTYgNDcuOTY1OCA2NS43MjE2IDQ3Ljk2NThDNjMuMzE1NyA0Ny45NjU4IDYxLjIzMyA0Ni4xNzA0IDYx" \
        "LjIzMyA0Mi41Nzk1QzYxLjIzMyAzOC45ODg1IDYzLjMxNTcgMzcuMTkzMSA2NS43MjE2IDM3LjE5MzFDNjguMDkx" \
        "NiAzNy4xOTMxIDcwLjIxMDMgMzguOTg4NSA3MC4yMTAzIDQyLjU3OTVaIiBmaWxsPSIjRkZGREY4Ii8+Cjwvc3Zn" \
        "Pg==",
        String
      )

      sig { override.returns(String) }
      def name = "Phantom"

      sig { override.returns(String) }
      def url = "https://phantom.app"

      sig { override.returns(String) }
      def icon = PHANTOM_ICON

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

      # Server-side adapters do not initiate connections directly.
      sig { override.void }
      def connect
        raise WalletNotReadyError,
              "PhantomWalletAdapter is a server-side adapter; connection is initiated in the browser"
      end

      sig { override.void }
      def disconnect
        # no-op on server side
      end

      # send_transaction is inherited from BaseSignerWalletAdapter and will
      # forward raw bytes to the RPC endpoint. Override here if you need
      # custom logic (e.g. a different commitment level for Phantom).
      sig do
        override
          .params(
            transaction: Transaction,
            rpc_url:     String,
            options:     SendTransactionOptions
          )
          .returns(String)
      end
      def send_transaction(transaction, rpc_url, options = SendTransactionOptions.new)
        raise WalletNotConnectedError,
              "send_transaction must be called with a pre-signed transaction on the server side"
      end

      # Server-side adapters cannot sign – signing is done in the browser.
      sig { override.params(transaction: Transaction).returns(Transaction) }
      def sign_transaction(transaction)
        raise WalletNotConnectedError,
              "sign_transaction must be performed client-side by the Phantom extension"
      end

      sig { override.params(transactions: T::Array[Transaction]).returns(T::Array[Transaction]) }
      def sign_all_transactions(transactions)
        raise WalletNotConnectedError,
              "sign_all_transactions must be performed client-side by the Phantom extension"
      end

      sig { override.params(message: String).returns(String) }
      def sign_message(message)
        raise WalletNotConnectedError,
              "sign_message must be performed client-side by the Phantom extension"
      end
    end
  end
end
