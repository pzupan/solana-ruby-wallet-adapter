# frozen_string_literal: true
# typed: strict

module SolanaWalletAdapter
  # Mixin for adapters that can sign arbitrary byte messages.
  # Mirrors MessageSignerWalletAdapterProps from @solana/wallet-adapter-base.
  module MessageSignerWalletAdapter
    extend T::Sig
    extend T::Helpers

    requires_ancestor { BaseWalletAdapter }

    # Sign an arbitrary message and return the 64-byte Ed25519 signature.
    sig do
      abstract
        .params(message: String) # binary string
        .returns(String)         # 64-byte binary signature
    end
    def sign_message(message); end
  end

  # Abstract base class combining transaction + message signing.
  # Mirrors BaseMessageSignerWalletAdapter from @solana/wallet-adapter-base.
  class BaseMessageSignerWalletAdapter < BaseSignerWalletAdapter
    extend  T::Sig
    extend  T::Helpers
    include MessageSignerWalletAdapter

    abstract!
  end

  # -------------------------------------------------------------------------
  # Sign-In-With-Solana (SIWS) support
  # Mirrors SignInMessageSignerWalletAdapterProps from @solana/wallet-adapter-base.
  # -------------------------------------------------------------------------

  # Input parameters for a SIWS sign-in request.
  class SignInInput < T::Struct
    # The domain presenting the sign-in request (e.g. "example.com").
    const :domain,      String

    # The Solana address being authenticated.
    const :address,     String

    # Human-readable statement.
    const :statement,   T.nilable(String), default: nil

    # URI of the resource that is the subject of the signing.
    const :uri,         T.nilable(String), default: nil

    # Version of the SIWS message specification.
    const :version,     String,            default: "1"

    # Unique nonce to prevent replay attacks.
    const :nonce,       T.nilable(String), default: nil

    # ISO 8601 datetime of when the sign-in was issued.
    const :issued_at,   T.nilable(String), default: nil

    # ISO 8601 datetime after which the sign-in expires.
    const :expiration_time, T.nilable(String), default: nil

    # ISO 8601 datetime after which the sign-in is valid.
    const :not_before, T.nilable(String), default: nil

    # Randomised value for this request (request ID).
    const :request_id, T.nilable(String), default: nil

    # List of information or references the dapp requests to be included.
    const :resources,  T::Array[String],  default: []

    # Builds the canonical EIP-4361-like SIWS message string.
    sig { returns(String) }
    def to_message
      lines = ["#{domain} wants you to sign in with your Solana account:"]
      lines << address
      lines << "" << (statement || "") << ""
      lines << "URI: #{uri}"          if uri
      lines << "Version: #{version}"
      lines << "Nonce: #{nonce}"      if nonce
      lines << "Issued At: #{issued_at}" if issued_at
      lines << "Expiration Time: #{expiration_time}" if expiration_time
      lines << "Not Before: #{not_before}" if not_before
      lines << "Request ID: #{request_id}" if request_id
      resources.each_with_index do |r, i|
        lines << "Resources:" if i.zero?
        lines << "- #{r}"
      end
      lines.join("\n")
    end
  end

  # Output from a completed SIWS sign-in.
  class SignInOutput < T::Struct
    # The account that signed in.
    const :address,   String

    # The signed SIWS message bytes (UTF-8 binary).
    const :signed_message, String

    # The 64-byte Ed25519 signature.
    const :signature, String

    # The type of signature (always "ed25519" for Solana).
    const :signature_type, String, default: "ed25519"
  end

  # Abstract base class that adds sign-in capability.
  class BaseSignInMessageSignerWalletAdapter < BaseMessageSignerWalletAdapter
    extend  T::Sig
    extend  T::Helpers

    abstract!

    # Perform a SIWS sign-in flow.  Returns a +SignInOutput+.
    sig do
      abstract
        .params(input: T.nilable(SignInInput))
        .returns(SignInOutput)
    end
    def sign_in(input = nil); end
  end
end
