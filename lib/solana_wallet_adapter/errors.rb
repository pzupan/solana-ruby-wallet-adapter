# frozen_string_literal: true
# typed: strict

module SolanaWalletAdapter
  # Base error for all wallet-adapter errors.
  # Mirrors WalletError from @solana/wallet-adapter-base.
  class WalletError < StandardError
    extend T::Sig

    sig { returns(T.nilable(Exception)) }
    attr_reader :cause_error

    sig { params(message: T.nilable(String), cause_error: T.nilable(Exception)).void }
    def initialize(message = nil, cause_error = nil)
      super(message)
      @cause_error = cause_error
    end
  end

  # Raised when a wallet is not in a ready / installed state.
  class WalletNotReadyError < WalletError; end

  # Raised when the wallet extension / app fails to load.
  class WalletLoadError < WalletError; end

  # Raised when the wallet adapter is misconfigured.
  class WalletConfigError < WalletError; end

  # Raised when the wallet connection attempt fails.
  class WalletConnectionError < WalletError; end

  # Raised when the wallet disconnects unexpectedly.
  class WalletDisconnectedError < WalletError; end

  # Raised when an explicit disconnect request fails.
  class WalletDisconnectionError < WalletError; end

  # Raised when the wallet returns an unexpected account.
  class WalletAccountError < WalletError; end

  # Raised when the wallet returns an invalid public key.
  class WalletPublicKeyError < WalletError; end

  # Raised for keypair-level errors.
  class WalletKeypairError < WalletError; end

  # Raised when an operation requires a connected wallet.
  class WalletNotConnectedError < WalletError; end

  # Raised when sending a transaction fails.
  class WalletSendTransactionError < WalletError; end

  # Raised when signing a transaction fails.
  class WalletSignTransactionError < WalletError; end

  # Raised when signing a message fails.
  class WalletSignMessageError < WalletError; end

  # Raised when a Sign-In-With-Solana flow fails.
  class WalletSignInError < WalletError; end

  # Raised when a wallet operation times out.
  class WalletTimeoutError < WalletError; end

  # Raised when a popup window is blocked.
  class WalletWindowBlockedError < WalletError; end

  # Raised when the user closes the wallet popup.
  class WalletWindowClosedError < WalletError; end
end
