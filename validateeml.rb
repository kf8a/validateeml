require 'nokogiri'
require 'open-uri'
require 'rest_client'

class CheckEML

  def initialize(url='http://lter.kbs.msu.edu/datasets?Dataset=all')
    begin
      @harvest_list = url
    ensure
      @errors = []
      @reports = []
    end
  end
  
  def check_harvest_list
    harvestList = Nokogiri::XML(open(@harvest_list))
    urls = harvestList.css('documentURL').collect {|x| x.text }

    urls.each do |url|
      check_dataset(url)
    end

    print_errors
    print_reporst
  end

  def check_dataset(url)
    doc = Nokogiri::XML(open(url))

    eml_scope, doc_id, version = doc.root.attributes['packageId'].value.split(/\./)
    data_entities =  doc.xpath('//dataTable/entityName').collect {|x| x.text }

    if check_with_eml_validator(url)
      if created_dataset_in_nis(url)
        if have_any_data_entities_been_created?(eml_scope, doc_id, version)
          read_nis_data_reports(data_entities, eml_scope, doc_id, version)
        end
      end
    end    
  end


  def created_dataset_in_nis(url)
      # use Request.execute because we want to disable the timeout.
      check_with { RestClient::Request.execute(:method=>:post, 
                                               :url =>'http://data.lternet.edu/data/eml?mode=evaluate', 
                                               :payload => url, 
                                               :timeout => -1)}
  end

  def have_any_data_entities_been_created?(eml_scope, doc_id, version)
    url = "http://data.lternet.edu/data/eml/NIS-#{eml_scope}/#{doc_id}/#{version}"
    check_with { RestClient.get url}
  end

  def read_nis_data_reports(data_entities, eml_scope, doc_id, version)
      data_entities.each do | entity |
        begin
          url = "http://data.lternet.edu/data/eml/NIS-#{eml_scope}/#{doc_id}/#{version}/#{entity}/report"
          response = RestClient.get url
          if response.code == 200
            print '.'
            @reports.push response.body
          else
            @errors.push EMLCheckError.new(url, response.body)
            print 'F'
          end
        rescue RestClient::Exception => e
          fail_with_message(url, e.response.body)
        end
     end
  end

  def check_with_eml_validator(url)
    doc = Nokogiri::XML(open(url))
    response = RestClient.post('http://knb.ecoinformatics.org/emlparser/parse', 
                               :action=>'textparse', :doctext=> doc.to_s)
    results = Nokogiri::HTML(response).xpath('//h2')
    results.each do |result|
      if result.text =~ /Passed/
        print '.'
      else
        fail_with_message(url, result.text)
      end
    end
  end

  def print_errors
    @errors.each do |error|
      if error.message =~ /Internal Server Error/
        error.message = 'Internal Server Error'
      end
      print "#{error.url}: #{error.message}\n"
    end
    p @errors
  end

  def print_reports
    p @reports
  end

  private

  def check_with
    result = false
    begin
      response = yield 
      result = true
       pass_fail(url, response) 
    rescue RestClient::Exception => e
      @errors.push EMLCheckError.new(url, e.response.body)
      print 'F'
    end
    result
  end

  def fail_with_message(url, message) 
    print 'F'
    @errors.push(url, message)
  end

  def pass_fail(url, response)
    if response.code == 200
      print '.'
    else
      @errors.push EMLCheckError.new(url, response.body)
      print 'F'
    end
  end

end

EMLCheckError  = Struct.new(:url, :error)
if __FILE__ == $0
  url = ARGV[0] || 'http://lter.kbs.msu.edu/datasets?Dataset=all'

  c = CheckEML.new(url)
  c.check_harvest_list
end
