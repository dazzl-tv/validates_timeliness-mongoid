# frozen_string_literal: true

require 'spec_helper'

describe ValidatesTimeliness, Mongoid do
  after { Mongoid.purge! }

  let(:article) { Faker::Article }

  context 'with validation methods' do
    let(:record) { article.new }

    it 'is defined on the class' do
      expect(article).to respond_to(:validates_date)
      expect(article).to respond_to(:validates_time)
      expect(article).to respond_to(:validates_datetime)
    end

    it 'is defined on the instance' do
      expect(record).to respond_to(:validates_date)
      expect(record).to respond_to(:validates_time)
      expect(record).to respond_to(:validates_datetime)
    end

    it 'validates a valid value string' do
      record.publish_date = Date.parse '2012-01-01'

      record.valid?
      expect(record.errors[:publish_date]).to be_empty
    end

    it 'validates a nil value' do
      record.publish_date = nil

      record.valid?
      expect(record.errors[:publish_date]).to be_empty
    end
  end

  it 'determines type for attribute' do
    expect(article.timeliness_attribute_type(:publish_date)).to eq :date
    expect(article.timeliness_attribute_type(:publish_time)).to eq :time
    expect(article.timeliness_attribute_type(:publish_datetime)).to eq :datetime
  end

  context 'with attribute write method' do
    let(:record) { article.new }

    it 'caches attribute raw value' do
      record.publish_datetime = date_string = '2010-01-01'

      expect(record.read_timeliness_attribute_before_type_cast('publish_datetime')).to eq date_string
    end

    context 'with plugin parser' do
      before { described_class.use_plugin_parser = true }

      after { described_class.use_plugin_parser = false }

      let(:record) { article.new }

      context 'with date columns' do
        it 'parses a string value', broken: true do
          allow(Timeliness::Parser).to receive(:parse)

          record.update(publish_date: '2010-01-01')

          expect(Timeliness::Parser).to have_received(:parse)
        end

        it 'parses a invalid string value as nil', broken: true do
          allow(Timeliness::Parser).to receive(:parse)

          record.update(publish_date: 'not valid')

          expect(Timeliness::Parser).to have_received(:parse)
        end

        it 'stores a Date value after parsing string' do
          record.publish_date = '2010-01-01'

          expect(record.publish_date).to be_kind_of(Date)
          expect(record.publish_date).to eq Date.new(2010, 1, 1)
        end
      end

      context 'with time columns' do
        it 'parses a string value', broken: true do
          allow(Timeliness::Parser).to receive(:parse)

          record.update(publish_time: '12:30')

          expect(Timeliness::Parser).to have_received(:parse)
        end

        it 'parses a invalid string value as nil', broken: true do
          allow(Timeliness::Parser).to receive(:parse)

          record.update(publish_time: 'not valid')

          expect(Timeliness::Parser).to have_received(:parse)
        end

        it 'stores a Time value after parsing string' do
          record.publish_time = '12:30'

          expect(record.publish_time).to be_kind_of(Time)
          expect(record.publish_time).to eq Time.new(Time.now.year,
                                                     Time.now.month,
                                                     Time.now.day, 12, 30)
        end
      end

      context 'with datetime columns' do
        let(:time_zone) { Faker::Address.time_zone }

        it 'parses a string value', broken: true do
          allow(Timeliness::Parser).to receive(:parse)

          record.update(publish_datetime: '2010-01-01 12:00')

          expect(Timeliness::Parser).to have_received(:parse)
        end

        it 'parses a invalid string value as nil', broken: true do
          allow(Timeliness::Parser).to receive(:parse)

          record.update(publish_datetime: 'not valid')

          expect(Timeliness::Parser).to have_received(:parse)
        end

        it 'parses string into DateTime value' do
          record.publish_datetime = '2010-01-01 12:00'

          expect(record.publish_datetime).to be_kind_of(DateTime)
        end

        it 'parses string as current timezone' do
          record.update(publish_datetime: DateTime.new)

          expect(record.publish_datetime.utc_offset).to eq \
            Time.local(time_zone).utc_offset
        end
      end
    end
  end

  context 'with cached values' do
    it 'is cleared on reload' do
      record = article.create!
      record.publish_date = '2010-01-01'
      record.reload
      expect(record.read_timeliness_attribute_before_type_cast('publish_date')).to be_nil
    end
  end

  context 'with before_type_cast method' do
    let(:record) { article.new }

    it 'is defined on class if ORM supports it' do
      expect(record).to respond_to(:publish_datetime_before_type_cast)
    end

    it 'returns original value' do
      record.publish_datetime = date_string = DateTime.now

      expect(record.publish_datetime_before_type_cast).to eq date_string
    end

    it 'returns attribute if no attribute assignment has been made' do
      time = Time.local(2010, 0o1, 0o1)
      article.create(publish_datetime: time)
      record = article.last
      expect(record.publish_datetime_before_type_cast).to eq time.to_datetime
    end

    context 'with plugin parser' do
      before { described_class.use_plugin_parser = true }

      after { described_class.use_plugin_parser = true }

      it 'returns original value' do
        record.publish_datetime = date_string = '2010-01-31'
        expect(record.publish_datetime_before_type_cast).to eq date_string
      end
    end
  end

  context 'with aliased fields' do
    before { described_class.use_plugin_parser = true }

    after { described_class.use_plugin_parser = false }

    it 'determines type for attribute' do
      expect(article.timeliness_attribute_type(:publish_date)).to eq :date
      expect(article.timeliness_attribute_type(:publish_time)).to eq :time
      expect(article.timeliness_attribute_type(:publish_datetime)).to eq :datetime
    end
  end
end
