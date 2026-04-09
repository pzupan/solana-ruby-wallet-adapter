# frozen_string_literal: true
# typed: strict

require "ed25519"

module SolanaWalletAdapter
  # Server-side Ed25519 signature verification for Solana.
  #
  # Usage:
  #   verifier = SolanaWalletAdapter::SignatureVerifier.new
  #
  #   # Verify a raw message + signature
  #   verifier.verify!(
  #     public_key: PublicKey.new("..."),
  #     message:    "hello world",
  #     signature:  Base64.decode64("...") # 64-byte binary
  #   )
  #
  #   # Verify a SIWS sign-in output
  #   verifier.verify_sign_in!(input: sign_in_input, output: sign_in_output)
  class SignatureVerifier
    extend T::Sig

    # Verify that +signature+ was produced by the holder of +public_key+
    # over +message+.  Raises +WalletSignMessageError+ on failure.
    sig do
      params(
        public_key: PublicKey,
        message:    String,   # arbitrary binary / UTF-8 bytes
        signature:  String    # 64-byte binary Ed25519 signature
      ).returns(T::Boolean)
    end
    def verify(public_key:, message:, signature:)
      vk = Ed25519::VerifyKey.new(public_key.bytes)
      vk.verify(signature, message)
      true
    rescue Ed25519::VerifyError
      false
    end

    # Same as +verify+ but raises +WalletSignMessageError+ on failure.
    sig do
      params(
        public_key: PublicKey,
        message:    String,
        signature:  String
      ).void
    end
    def verify!(public_key:, message:, signature:)
      return if verify(public_key: public_key, message: message, signature: signature)

      raise WalletSignMessageError, "Signature verification failed for public key #{public_key}"
    end

    # Verify a complete SIWS sign-in output against its input.
    # Raises +WalletSignInError+ on failure.
    sig do
      params(
        input:  SignInInput,
        output: SignInOutput
      ).void
    end
    def verify_sign_in!(input:, output:)
      unless output.address == input.address
        raise WalletSignInError,
              "Sign-in address mismatch: expected #{input.address}, got #{output.address}"
      end

      expected_message = input.to_message
      unless output.signed_message == expected_message
        raise WalletSignInError, "Sign-in message does not match the expected SIWS message"
      end

      public_key = PublicKey.new(output.address)
      verify!(
        public_key: public_key,
        message:    output.signed_message,
        signature:  output.signature
      )
    rescue WalletError
      raise
    rescue => e
      raise WalletSignInError.new(e.message, e)
    end
  end
end
