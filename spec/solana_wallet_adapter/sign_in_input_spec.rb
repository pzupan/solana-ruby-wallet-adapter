# frozen_string_literal: true

require "spec_helper"

RSpec.describe SolanaWalletAdapter::SignInInput do
  subject(:input) do
    described_class.new(
      domain:    "example.com",
      address:   "11111111111111111111111111111111",
      statement: "Sign in to Example",
      uri:       "https://example.com",
      nonce:     "abc123",
      issued_at: "2024-01-01T00:00:00Z"
    )
  end

  describe "#to_message" do
    it "starts with the domain line" do
      expect(input.to_message).to start_with("example.com wants you to sign in")
    end

    it "includes the address" do
      expect(input.to_message).to include("11111111111111111111111111111111")
    end

    it "includes the statement" do
      expect(input.to_message).to include("Sign in to Example")
    end

    it "includes the nonce" do
      expect(input.to_message).to include("Nonce: abc123")
    end

    it "includes the URI" do
      expect(input.to_message).to include("URI: https://example.com")
    end
  end
end
