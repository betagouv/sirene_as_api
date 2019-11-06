require 'rails_helper'

describe Stock::Operation::LoadEtablissement, vcr: { cassette_name: 'cquest_geo_sirene_may_OK' } do
  subject { described_class.call logger: logger }

  let(:logger) { instance_spy Logger }
  let(:expected_uri) { 'http://data.cquest.org/geo_sirene/v2019/2019-05/StockEtablissement_utf8_geo.csv.gz' }

  context 'when remote stock is importable (newer)' do
    before { create :stock_etablissement, :completed, month: '04' }

    it { is_expected.to be_success }

    it 'logs import will start' do
      subject
      expect(logger)
        .to have_received(:info)
        .with('New stock found 05, will import...')
    end

    it 'shedule a new ImportStockJob' do
      expect { subject }
        .to have_enqueued_job(ImportStockJob)
        .on_queue('sirene_api_test_stock')
    end

    it 'persist a new stock to import' do
      expect { subject }.to change(StockEtablissement, :count).by(1)
    end

    its([:remote_stock]) { is_expected.to be_persisted }
    its([:remote_stock]) do
      is_expected.to have_attributes(uri: expected_uri, status: 'PENDING', month: '05', year: '2019')
    end
  end

  context 'when remote stock is not importable (same)' do
    before { create :stock_etablissement, :completed, month: '05' }

    it { is_expected.to be_failure }

    it 'logs a warning' do
      subject
      expect(logger)
        .to have_received(:warn)
        .with('Remote stock not importable (remote month: 05, current (COMPLETED) month: 05)')
    end

    its([:remote_stock]) { is_expected.not_to be_persisted }

    it 'does not enqueue job' do
      expect { subject }
        .not_to have_enqueued_job ImportStockJob
    end
  end

  describe 'Integration: from download to import', :perform_enqueued_jobs do
    let(:stock_model) { StockEtablissement }
    let(:imported_month) { '05' }
    let(:expected_sirens) { %w[005880034 006003560 006004659] }

    let(:expected_tmp_file) do
      Rails.root.join 'tmp', 'files', 'sample_etablissements.csv'
    end

    let(:mocked_downloaded_file) do
      Rails.root.join('spec', 'fixtures', 'sample_etablissements.csv.gz').to_s
    end

    it_behaves_like 'importing csv'
  end
end
