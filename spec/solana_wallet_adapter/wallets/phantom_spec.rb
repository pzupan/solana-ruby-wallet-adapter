# frozen_string_literal: true

require "spec_helper"

RSpec.describe SolanaWalletAdapter::Wallets::PhantomWalletAdapter do
  subject(:adapter) { described_class.new }

  it "has the correct name" do
    expect(adapter.name).to eq("Phantom")
  end

  it "has the correct url" do
    expect(adapter.url).to eq("https://phantom.app")
  end

  it "has an icon string" do
    expect(adapter.icon).to start_with("data:image/svg+xml;base64,")
  end

  it "reports Unsupported ready state on the server" do
    expect(adapter.ready_state).to eq(SolanaWalletAdapter::WalletReadyState::Unsupported)
  end

  it "is not connected" do
    expect(adapter.connected?).to be false
    expect(adapter.public_key).to be_nil
  end

  it "raises WalletNotReadyError on connect" do
    expect { adapter.connect }.to raise_error(SolanaWalletAdapter::WalletNotReadyError)
  end

  it "raises WalletNotConnectedError on sign_transaction" do
    tx = SolanaWalletAdapter::Transaction.new("\x00" * 64)
    expect { adapter.sign_transaction(tx) }
      .to raise_error(SolanaWalletAdapter::WalletNotConnectedError)
  end

  it "raises WalletNotConnectedError on sign_message" do
    expect { adapter.sign_message("hello") }
      .to raise_error(SolanaWalletAdapter::WalletNotConnectedError)
  end

  describe "#to_h" do
    subject(:hash) { adapter.to_h }

    it "includes required metadata keys" do
      expect(hash.keys).to include("name", "url", "icon", "readyState", "connected", "publicKey")
    end

    it "sets connected to false" do
      expect(hash["connected"]).to be false
    end
  end

  describe "#supported_transaction_versions" do
    it "includes legacy and version 0" do
      versions = adapter.supported_transaction_versions
      expect(versions).to include(SolanaWalletAdapter::TransactionVersion::Legacy)
      expect(versions).to include(SolanaWalletAdapter::TransactionVersion::Version0)
    end
  end
end
