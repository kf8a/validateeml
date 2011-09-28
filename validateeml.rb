require 'check_eml'

if __FILE__ == $0
  url = ARGV[0] || 'http://lter.kbs.msu.edu/datasets?Dataset=all'

  c = CheckEML.new(url)
  c.check_harvest_list
end
