require "spec_helper"

describe InfluxDB::PointValue do
  describe "escaping" do
    let(:data) do
      {
        series: '1= ,"\\1',
        tags: {'2= ,"\\2' => '3= ,"\\3'},
        values: {'4= ,"\\4' => '5= ,"\\5'},
      }
    end

    it 'should escape correctly' do
      point = InfluxDB::PointValue.new(data)
      expected = %(1=\\ \\,"\\1,2\\=\\ \\,"\\2=3\\=\\ \\,"\\3 )+
                 %(4\\=\\ \\,\\"\\4="5= ,\\"\\5")
      expect(point.dump).to eq(expected)
    end
  end

  describe 'dump' do
    context "with all possible data passed" do
      let(:expected_value) do
        'responses,region=eu,status=200 value=5,threshold=0.54 1436349652'
      end
      it 'should have proper form' do
        point = InfluxDB::PointValue.new(series: "responses",
                                         values: { value: 5, threshold: 0.54 },
                                         tags: { region: 'eu', status: 200 },
                                         timestamp: 1_436_349_652)

        expect(point.dump).to eq(expected_value)
      end
    end

    context "with no tags" do
      let(:expected_value) do
        "responses value=5,threshold=0.54 1436349652"
      end
      it 'should have proper form' do
        point = InfluxDB::PointValue.new(series: "responses",
                                         values: { value: 5, threshold: 0.54 },
                                         timestamp: 1_436_349_652)

        expect(point.dump).to eq(expected_value)
      end
    end

    context "with values only" do
      let(:expected_value) do
        "responses value=5,threshold=0.54"
      end
      it 'should have proper form' do
        point = InfluxDB::PointValue.new(series: "responses",
                                         values: { value: 5, threshold: 0.54 })

        expect(point.dump).to eq(expected_value)
      end
    end
  end
end
