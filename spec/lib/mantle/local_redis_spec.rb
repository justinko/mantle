require 'spec_helper'

describe Mantle::LocalRedis do
  describe ".set_message_successfully_received" do
    it "saves the time" do
      time = "1234"
      response = Mantle::LocalRedis.set_message_successfully_received(time)
      expect(Mantle::LocalRedis.last_message_successfully_received_at).to eq(1234.0)
      expect(response).to eq(1234.0)
    end
  end

  describe ".last_message_successfully_received_at" do
    it "returns time as a float" do
      Mantle::LocalRedis.set_message_successfully_received
      expect(Mantle::LocalRedis.last_message_successfully_received_at).to be_a(Float)
    end

    it "returns nil if nothing has been set" do
      expect(Mantle::LocalRedis.last_message_successfully_received_at).to eq(nil)
    end
  end

  it 'sets and gets the last time the catch up was cleaned up' do
    Mantle::LocalRedis.set_catch_up_cleanup(1234.0)
    expect(Mantle::LocalRedis.last_catch_up_cleanup_at).to eq(1234.0)
  end
end

