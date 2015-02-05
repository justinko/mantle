require 'spec_helper'

describe Mantle::CatchUp::MessageKey do
  it "returns formatted string with time" do
    allow(Time).to receive_message_chain(:now, :utc, :to_f).and_return(1234.123)

    key = Mantle::CatchUp::MessageKey.new("update:person").key
    expect(key).to eq("1234.123:update:person")
  end

  it 'responds to to_s' do
    allow(Time).to receive_message_chain(:now, :utc, :to_f).and_return(1234.123)

    key_obj = Mantle::CatchUp::MessageKey.new("update:person")
    expect("#{key_obj}").to eq("1234.123:update:person")
  end
end