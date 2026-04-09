# frozen_string_literal: true

require "spec_helper"

RSpec.describe SolanaWalletAdapter::EventEmitter do
  let(:host) do
    Class.new do
      include SolanaWalletAdapter::EventEmitter
    end.new
  end

  describe "#on / #emit" do
    it "calls registered listeners with emitted arguments" do
      received = []
      host.on(:test) { |v| received << v }
      host.emit(:test, 42)
      expect(received).to eq([42])
    end

    it "supports multiple listeners for the same event" do
      calls = 0
      host.on(:test) { calls += 1 }
      host.on(:test) { calls += 1 }
      host.emit(:test)
      expect(calls).to eq(2)
    end
  end

  describe "#once" do
    it "fires only once then auto-removes itself" do
      count = 0
      host.once(:test) { count += 1 }
      host.emit(:test)
      host.emit(:test)
      expect(count).to eq(1)
    end
  end

  describe "#off" do
    it "removes a specific listener" do
      count   = 0
      handler = proc { count += 1 }
      host.on(:test, &handler)
      host.off(:test, handler)
      host.emit(:test)
      expect(count).to eq(0)
    end

    it "removes all listeners for an event when no block is given" do
      count = 0
      host.on(:test) { count += 1 }
      host.on(:test) { count += 1 }
      host.off(:test)
      host.emit(:test)
      expect(count).to eq(0)
    end
  end
end
