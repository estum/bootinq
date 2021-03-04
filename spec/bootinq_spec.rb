RSpec.describe Bootinq do
  it 'has a version number' do
    expect(Bootinq::VERSION).not_to be nil
  end

  describe ".deserialized_config" do
    let(:required_config) {
      {
        'default' => "s2",
        'parts' => { "A" => :api_part, "F" => :frontend_part, "s" => :shared },
        'mount' => { "a" => :api, 2 => :api2, "f" => :frontend },
        'deps'  => { :api_part => { "in" => "a2" }, :frontend_part => { "in" => "f" } }
      }
    }

    it 'correctly loads the required config' do
      expect(Bootinq.deserialized_config).to eq(required_config)
    end

    let(:given_config) {
      { 'env_key' => 'BOOTINQ', 'default' => "-f", 'parts' => nil, 'mount' => nil }
    }

    it 'correctly loads the given config' do
      expect(Bootinq.deserialized_config(path: File.expand_path("../lib/bootinq.yml", __dir__))).to eq(given_config)
    end
  end

  let(:shared_attrs) {{ name: "shared", group: :shared_boot }}
  let(:api_attrs)    {{ name: "api2",   group: :api2_boot,  engine: Api2::Engine }}
  let(:added_groups) { [:api_part_boot, :shared_boot, :api2_boot] }

  describe "#initialize" do
    it 'creates a singleton object' do
      expect(Bootinq.instance).to be_instance_of Bootinq
    end

    it 'takes default flags from bootinq.yml' do
      expect(Bootinq.flags).to eq(%w(A s 2))
    end

    it 'registers all components from bootinq.yml' do
      expect(Bootinq.components.size).to eq(3)
      expect(Bootinq.components).to include(:api_part, :shared, :api2)
    end
  end

  describe ".require" do
    it 'requires given rails parts' do
      expect( defined? ActionMailer ).to be_truthy
      expect( defined? Sprockets ).to be_falsey
    end

    it 'requires given components' do
      expect( defined? ApiPart ).to be_truthy
      expect( defined? FrontendPart ).to be_falsey
      expect( defined? Shared ).to be_truthy
      expect( defined? Api ).to be_falsey
      expect( defined? Api2 ).to be_truthy
    end
  end

  describe ".new" do
    it 'should be frozen' do
      expect(Bootinq.instance).to be_frozen
    end
  end

  describe '#is_dependency?' do
    it 'correctly detects dependency of enabled component' do
      expect(Bootinq.instance.is_dependency?(:api_part)).to be_truthy
    end
  end

  describe "#groups" do
    it 'returns array which contains Rails.group & enabled Bootinq components' do
      expect(Bootinq.groups).to contain_exactly(:default, 'test', *added_groups)
    end
  end

  describe "#enabled?" do
    it 'takes symbols' do
      expect(Bootinq.enabled?(:api_part)).to be_truthy
      expect(Bootinq.enabled?(:frontend_part)).to be_falsey
      expect(Bootinq.enabled?(:shared)).to be_truthy
      expect(Bootinq.enabled?(:frontend)).to be_falsey
    end

    it 'takes strings' do
      expect(Bootinq.enabled?('api')).to be_falsey
      expect(Bootinq.enabled?('api2')).to be_truthy
    end
  end

  describe "#component" do
    it 'takes symbols' do
      expect(Bootinq.component(:shared)).to have_attributes(shared_attrs) & satisfy { |val| !val.mountable? }
    end

    it 'takes strings' do
      expect(Bootinq.component('api2')).to be_mountable & have_attributes(api_attrs)
    end
  end

  describe "#each_mountable" do
    it 'enums only mountable components' do
      expect(Bootinq.each_mountable.to_a).to contain_exactly Bootinq.component(:api2)
    end
  end

  describe '#on' do
    context '(name)' do
      it 'yields a block if a component is enabled' do
        expect {|b| Bootinq.on(:shared, &b) }.to yield_with_no_args
        expect {|b| Bootinq.on(:frontend, &b) }.not_to yield_control
      end
    end

    context '(any: [*names])' do
      it 'yields a block if any component is enabled' do
        expect {|b| Bootinq.on(any: [:frontend, 'api2'], &b) }.to yield_with_no_args
        expect {|b| Bootinq.on(any: [:frontend], &b) }.not_to yield_control
      end
    end

    context '(all: [*names])' do
      it 'yields a block if every component is enabled' do
        expect {|b| Bootinq.on(all: [:shared, 'api2'], &b) }.to yield_with_no_args
        expect {|b| Bootinq.on(all: [:shared, :frontend], &b) }.not_to yield_control
      end
    end

    context 'no arguments' do
      it { expect {|b| Bootinq.on(&b) }.to raise_error(ArgumentError, "wrong arguments (given 0, expected 1)") }
    end

    context 'wrong arguments' do
      it { expect {|b| Bootinq.on(any: [:shared], all: ['api2'], &b) }.to raise_error(ArgumentError) }
    end
  end

  describe "#switch" do
    it 'yields control' do
      expect { |b| Bootinq.switch { |o| o.shared(&b) } }.to yield_control
    end
  end
end