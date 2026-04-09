# typed: true

module SolanaWalletAdapter
  class WalletError < StandardError
    sig { returns(T.nilable(Exception)) }
    def cause_error; end

    sig { params(message: T.nilable(String), cause_error: T.nilable(Exception)).void }
    def initialize(message = nil, cause_error = nil); end
  end

  class WalletNotReadyError < WalletError; end
  class WalletLoadError < WalletError; end
  class WalletConfigError < WalletError; end
  class WalletConnectionError < WalletError; end
  class WalletDisconnectedError < WalletError; end
  class WalletDisconnectionError < WalletError; end
  class WalletAccountError < WalletError; end
  class WalletPublicKeyError < WalletError; end
  class WalletKeypairError < WalletError; end
  class WalletNotConnectedError < WalletError; end
  class WalletSendTransactionError < WalletError; end
  class WalletSignTransactionError < WalletError; end
  class WalletSignMessageError < WalletError; end
  class WalletSignInError < WalletError; end
  class WalletTimeoutError < WalletError; end
  class WalletWindowBlockedError < WalletError; end
  class WalletWindowClosedError < WalletError; end
end
