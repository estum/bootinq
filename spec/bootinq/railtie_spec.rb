require 'spec_helper'

RSpec.describe Dummy::Application do
  it 'should be initialized as rails app' do
    expect(Rails.application).to be_instance_of(described_class)
  end

  it 'runs in test env' do
    expect(Rails.env).to be_test
  end
end

RSpec.describe Bootinq do
  describe '.rails_path' do
    subject(:rails_path) { described_class.rails_path }
    it { is_expected.to be_instance_of(Bootinq::RailsPath) }
  end

  describe '.component_paths_for' do
    subject(:paths) { described_class.component_paths_for(input_path) }

    context 'with default suffix path template' do
      context 'with directory as an input path' do
        let(:input_path) { 'config/locales' }
        let(:expected_list) { %w[config/locales.shared config/locales.api_part config/locales.api2] }
        it { is_expected.to match_array(expected_list) }
      end

      context 'with file as an input path' do
        let(:input_path) { 'config/routes.rb' }
        let(:expected_list) { %w[config/routes.shared.rb config/routes.api_part.rb config/routes.api2.rb] }
        it { is_expected.to match_array(expected_list) }
      end
    end

    context 'with subdir path template' do
      before { Bootinq.rails_path.template = Bootinq::RailsPath::TEMPLATES[:subdir] }

      context 'with directory as an input path' do
        let(:input_path) { 'config/locales' }
        let(:expected_list) { %w[config/locales/shared config/locales/api_part config/locales/api2] }
        it { is_expected.to match_array(expected_list) }
      end

      context 'with file as an input path' do
        let(:input_path) { 'config/routes.rb' }
        let(:expected_list) { %w[config/routes/shared.rb config/routes/api_part.rb config/routes/api2.rb] }
        it { is_expected.to match_array(expected_list) }
      end
    end
  end

  describe '.add_component_paths_to' do
    before { described_class.add_component_paths_to(paths_path) }
    subject(:paths_after) { paths_path.instance_variable_get(:@paths) }

    context 'with default suffix path template' do
      context 'with directory as an input path' do
        let(:paths_path) { Rails.configuration.paths['config/locales'] }
        let(:expected_list) { %w[config/locales.shared config/locales.api_part config/locales.api2] }
        it { is_expected.to include(*expected_list) }
      end

      context 'with directory as an input path' do
        let(:paths_path) { Rails.configuration.paths['config/initializers'] }
        let(:expected_list) { %w[config/initializers.shared config/initializers.api_part config/initializers.api2] }
        it { is_expected.to include(*expected_list) }
      end

      context 'with file as an input path' do
        let(:paths_path) { Rails.configuration.paths['config/routes.rb'] }
        let(:expected_list) { %w[config/routes.shared.rb config/routes.api_part.rb config/routes.api2.rb] }
        it { is_expected.to include(*expected_list) }
      end
    end

    context 'with subdir path template' do
      before { Bootinq.rails_path.template = Bootinq::RailsPath::TEMPLATES[:subdir] }
      after { Bootinq.rails_path.template = Bootinq::RailsPath::TEMPLATES[:default] }

      context 'with directory as an input path' do
        let(:paths_path) { Rails.configuration.paths['config/locales'] }
        let(:expected_list) { %w[config/locales/shared config/locales/api_part config/locales/api2] }
        it { is_expected.to include(*expected_list) }
      end

      context 'with file as an input path' do
        let(:paths_path) { Rails.configuration.paths['config/routes.rb'] }
        let(:expected_list) { %w[config/routes/shared.rb config/routes/api_part.rb config/routes/api2.rb] }
        it { is_expected.to include(*expected_list) }
      end
    end
  end

  context 'on initialized app' do
    # before { Rails.application.initialize! }

    it 'loads component-scoped initializers' do
      expect(Rails.application).to be_initialized
      expect(Bootinq.rails_path.template).to eq(Bootinq::RailsPath::TEMPLATES[:default])
    end

    it 'skips component-scoped initializers which is not enabled' do
      expect(Object).not_to be_const_defined(:FRONTEND_PART_CONSTANT)
    end
  end
end