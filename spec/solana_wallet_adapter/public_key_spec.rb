# frozen_string_literal: true

require "spec_helper"

RSpec.describe SolanaWalletAdapter::PublicKey do
  # A well-known Solana public key (System Program)
  SYSTEM_PROGRAM_B58 = "11111111111111111111111111111111"

  describe "#initialize" do
    it "accepts a Base58 string" do
      pk = described_class.new(SYSTEM_PROGRAM_B58)
      expect(pk.to_base58).to eq(SYSTEM_PROGRAM_B58)
    end

    it "accepts a 32-byte binary string" do
      raw = "\x00" * 32
      pk  = described_class.new(raw)
      expect(pk.bytes.bytesize).to eq(32)
    end

    it "accepts a 32-element Integer array" do
      arr = Array.new(32, 0)
      pk  = described_class.new(arr)
      expect(pk.to_bytes).to eq(arr)
    end

    it "raises ArgumentError for wrong byte length" do
      expect { described_class.new("\x00" * 10) }.to raise_error(ArgumentError)
    end
  end

  describe "#==" do
    it "considers two keys with the same bytes equal" do
      pk1 = described_class.new(SYSTEM_PROGRAM_B58)
      pk2 = described_class.new(SYSTEM_PROGRAM_B58)
      expect(pk1).to eq(pk2)
    end

    it "considers two keys with different bytes unequal" do
      pk1 = described_class.new(SYSTEM_PROGRAM_B58)
      pk2 = described_class.new(Array.new(32, 1))
      expect(pk1).not_to eq(pk2)
    end
  end

  describe "#inspect" do
    it "includes the Base58 representation" do
      pk = described_class.new(SYSTEM_PROGRAM_B58)
      expect(pk.inspect).to include(SYSTEM_PROGRAM_B58)
    end
  end
end
