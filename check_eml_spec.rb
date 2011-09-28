require 'rspec'
require File.expand_path(File.dirname(__FILE__) + '/validateeml')

describe CheckEML do

  describe 'validate eml' do
    it 'should validate'
  end

  describe "checking with the EML validator" do
    it 'should return true for a valid dataset' do
      RestClient.stub(:get).and_return(200)

    end
    it 'should parse the response'
  end


  describe 'gather a report' do
    it 'should construct a valid url'
    it 'should parse the response'
  end
end
