require 'spec_helper'

RSpec.describe Bootinq::Switch do
  let(:names)  { [:shared, :api] }
  let(:switch) { described_class.new(*names) }

  it "yields a block only if component is enabled" do
    expect {|b| switch.shared(&b) }.to yield_with_no_args
    expect {|b| switch.api(&b) }.to yield_with_no_args
  end

  it 'not yields a block if component is disabled' do
    expect {|b| switch.engine(&b) }.not_to yield_with_no_args
  end

  it 'not raises a error if component is unknown' do
    expect {|b| switch.something(&b) }.not_to raise_error
  end
end