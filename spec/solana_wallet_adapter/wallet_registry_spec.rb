# frozen_string_literal: true

require "spec_helper"

RSpec.describe SolanaWalletAdapter::WalletRegistry do
  describe ".register / .all / .find" do
    before do
      described_class.register(SolanaWalletAdapter::Wallets::PhantomWalletAdapter)
    end

    it "registers an adapter class" do
      expect(described_class.all).to include(SolanaWalletAdapter::Wallets::PhantomWalletAdapter)
    end

    it "finds an adapter by wallet name" do
      expect(described_class.find("Phantom")).to eq(SolanaWalletAdapter::Wallets::PhantomWalletAdapter)
    end

    it "returns nil for an unknown wallet name" do
      expect(described_class.find("UnknownWallet")).to be_nil
    end
  end

  describe ".to_json_array" do
    before do
      described_class.register(
        SolanaWalletAdapter::Wallets::PhantomWalletAdapter,
        SolanaWalletAdapter::Wallets::SolflareWalletAdapter
      )
    end

    it "returns an array of hashes with metadata keys" do
      arr = described_class.to_json_array
      expect(arr.size).to eq(2)
      arr.each do |h|
        expect(h).to include("name", "url", "icon", "readyState")
      end
    end
  end

  describe ".reset!" do
    it "clears all registered adapters" do
      described_class.register(SolanaWalletAdapter::Wallets::PhantomWalletAdapter)
      described_class.reset!
      expect(described_class.all).to be_empty
    end
  end
end
