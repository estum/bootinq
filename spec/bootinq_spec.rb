require 'spec_helper'

describe Bootinq do
  it 'has a version number' do
    expect(Bootinq::VERSION).not_to be nil
  end

  let(:shared_attrs) {{ mountable: false, group: :shared_boot }}
  let(:api_attrs)    {{ mountable: true, group: :api_boot }}

  describe "#initialize" do
    it 'Creates singleton object' do
      expect(Bootinq.instance).to be_instance_of Bootinq
    end

    it 'Takes default flags from bootinq.yml' do
      expect(Bootinq.flags).to eq(["s", "a"])
    end

    it 'Registers all components from bootinq.yml' do
      expect(Bootinq.components.size).to eq(2)
    end
  end

  describe ".require" do
    it 'Requires given rails parts' do
      expect( defined? ActionMailer ).to be_truthy
      expect( defined? Sprockets ).to be_falsey
    end

    it 'Requires given components' do
      expect( defined? Shared ).to be_truthy
      expect( defined? Api ).to be_truthy
      expect( defined? Frontend ).to be_falsey
    end
  end

  describe ".new" do
    it 'Should be frozen' do
      expect(Bootinq.instance).to be_frozen
    end
  end

  describe "#component" do
    it 'Fetches correct component by name' do
      expect(Bootinq.component(:shared)).to have_attributes shared_attrs
      expect(Bootinq.component(:api)).to have_attributes api_attrs
    end
  end

  describe "#each_mountable" do
    it 'Enums only mountable components' do
      expect(Bootinq.each_mountable.to_a).to contain_exactly Bootinq.component(:api)
    end
  end

  describe "#groups" do
    it 'Returns array which contains Rails.group & enabled Bootinq components' do
      expect(Bootinq.groups).to contain_exactly(:default, 'test', :shared_boot, :api_boot)
    end
  end
end
