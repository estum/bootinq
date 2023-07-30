require 'bootinq/component'
require 'bootinq/rails_path'

class Bootinq
  RSpec.describe RailsPath do
    let(:api_component) { Component.new(:api) }

    let(:default_tpl) { RailsPath::TEMPLATES[:default] }
    let(:subdir_tpl) { RailsPath::TEMPLATES[:subdir] }

    let(:default_rails_path) { described_class.new }
    let(:subdir_rails_path) { described_class.new(subdir_tpl) }

    subject(:rails_path) { default_rails_path }

    describe '#initialize' do
      it 'initializes by default with a suffix template' do
        expect(default_rails_path).to have_attributes(template: eq(default_tpl))
      end

      it 'can be initialized with a subdir template' do
        expect(subdir_rails_path).to have_attributes(template: eq(subdir_tpl))
      end
    end

    describe '#template=' do
      before { rails_path.template = subdir_tpl }
      it { is_expected.to have_attributes(template: eq(subdir_tpl)) }
    end

    describe '#call' do
      context '(path, component)' do
        let(:component) { api_component }

        subject(:generated_path) { rails_path.(path, component) }

        context 'on default template' do
          context 'with directory as a path' do
            let(:path) { 'config/initializers' }
            it { is_expected.to eq('config/initializers.api') }
          end

          context 'with file as a path' do
            let(:path) { 'config/routes.rb' }
            it { is_expected.to eq('config/routes.api.rb') }
          end
        end

        context 'on subdir template' do
          before { rails_path.template = subdir_tpl }

          context 'with directory as a path' do
            let(:path) { 'config/initializers' }
            it { is_expected.to eq('config/initializers/api') }
          end

          context 'with file as a path' do
            let(:path) { 'config/routes.rb' }
            it { is_expected.to eq('config/routes/api.rb') }
          end
        end
      end

      context '(path)' do
        let(:path) { 'config/initializers' }
        subject(:curried_proc) { rails_path.(path) }

        it { is_expected.to be_kind_of(Proc) }

        context 'on result of yielding the curried proc' do
          subject(:result_of_proc) { curried_proc.(api_component) }
          it { is_expected.to be_kind_of(String) }
          it { is_expected.to eq('config/initializers.api') }
        end
      end
    end
  end
end
