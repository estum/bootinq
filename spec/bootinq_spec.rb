RSpec.describe Bootinq do
  it 'has a version number' do
    expect(Bootinq::VERSION).not_to be nil
  end

  let(:shared_attrs) {{ name: "shared", group: :shared_boot }}
  let(:api_attrs)    {{ name: "api",    group: :api_boot,  engine: Api::Engine }}
  let(:added_groups) { [:shared_boot, :api_boot] }

  describe "#initialize" do
    it 'creates a singleton object' do
      expect(Bootinq.instance).to be_instance_of Bootinq
    end

    it 'takes default flags from bootinq.yml' do
      expect(Bootinq.flags).to eq(["s", "a"])
    end

    it 'registers all components from bootinq.yml' do
      expect(Bootinq.components.size).to eq(2)
      expect(Bootinq.components).to include(:shared, :api)
    end
  end

  describe ".require" do
    it 'requires given rails parts' do
      expect( defined? ActionMailer ).to be_truthy
      expect( defined? Sprockets ).to be_falsey
    end

    it 'requires given components' do
      expect( defined? Shared ).to be_truthy
      expect( defined? Api ).to be_truthy
    end
  end

  describe ".new" do
    it 'should be frozen' do
      expect(Bootinq.instance).to be_frozen
    end
  end

  describe "#groups" do
    it 'returns array which contains Rails.group & enabled Bootinq components' do
      expect(Bootinq.groups).to contain_exactly(:default, 'test', *added_groups)
    end
  end

  describe "#enabled?" do
    it 'takes symbols' do
      expect(Bootinq.enabled?(:shared)).to be_truthy
      expect(Bootinq.enabled?(:frontend)).to be_falsey
    end

    it 'takes strings' do
      expect(Bootinq.enabled?('api')).to be_truthy
      expect(Bootinq.enabled?('frontend')).to be_falsey
    end
  end

  describe "#component" do
    it 'takes symbols' do
      expect(Bootinq.component(:shared)).to have_attributes(shared_attrs) & satisfy { |val| !val.mountable? }
    end

    it 'takes strings' do
      expect(Bootinq.component('api')).to be_mountable & have_attributes(api_attrs)
    end
  end

  describe "#each_mountable" do
    it 'enums only mountable components' do
      expect(Bootinq.each_mountable.to_a).to contain_exactly Bootinq.component(:api)
    end
  end

  describe '#on' do
    context '(name)' do
      it 'yields a block if a component is enabled' do
        expect {|b| Bootinq.on(:shared, &b) }.to yield_with_no_args
        expect {|b| Bootinq.on(:engine, &b) }.not_to yield_control
      end
    end

    context '(any: [*names])' do
      it 'yields a block if any component is enabled' do
        expect {|b| Bootinq.on(any: [:engine, 'api'], &b) }.to yield_with_no_args
        expect {|b| Bootinq.on(any: [:engine], &b) }.not_to yield_control
      end
    end

    context '(all: [*names])' do
      it 'yields a block if every component is enabled' do
        expect {|b| Bootinq.on(all: [:shared, 'api'], &b) }.to yield_with_no_args
        expect {|b| Bootinq.on(all: [:shared, :engine], &b) }.not_to yield_control
      end
    end
  end
end