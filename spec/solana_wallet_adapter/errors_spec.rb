# frozen_string_literal: true

require "spec_helper"

RSpec.describe SolanaWalletAdapter::WalletError do
  it "is a StandardError" do
    expect(described_class.ancestors).to include(StandardError)
  end

  it "stores a cause_error" do
    cause = RuntimeError.new("root cause")
    err   = described_class.new("outer message", cause)
    expect(err.cause_error).to eq(cause)
    expect(err.message).to eq("outer message")
  end

  error_classes = %w[
    WalletNotReadyError WalletLoadError WalletConfigError
    WalletConnectionError WalletDisconnectedError WalletDisconnectionError
    WalletAccountError WalletPublicKeyError WalletKeypairError
    WalletNotConnectedError WalletSendTransactionError WalletSignTransactionError
    WalletSignMessageError WalletSignInError WalletTimeoutError
    WalletWindowBlockedError WalletWindowClosedError
  ]

  error_classes.each do |klass_name|
    it "#{klass_name} inherits from WalletError" do
      klass = SolanaWalletAdapter.const_get(klass_name)
      expect(klass.ancestors).to include(SolanaWalletAdapter::WalletError)
    end
  end
end
