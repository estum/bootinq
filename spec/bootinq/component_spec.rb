require 'spec_helper'

RSpec.describe Bootinq do
  shared_examples 'component' do
    let(:component) { described_class.new(name) }

    it { expect(component).to eq(name.to_s) & eq(name.to_sym) }

    describe '#initialize' do
      it { expect(component).to be_frozen }
    end

    describe '#name' do
      it { expect(component.name).to be_frozen & eq(name.to_s) }
    end

    describe '#mountable?' do
      it { expect(component.mountable?).to be mountable }
    end

    describe '#engine' do
      it { expect(component.engine).to eq engine }
    end
  end

  describe Bootinq::Component do
    let!(:name)      { :shared }
    let!(:mountable) { false }
    let!(:engine)    { nil }
    it_behaves_like 'component'
  end

  describe Bootinq::Mountable do
    let!(:name)      { :api2 }
    let!(:mountable) { true }
    let!(:engine)    { Api2::Engine }
    it_behaves_like 'component'
  end
end
