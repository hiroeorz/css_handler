$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'css_handler'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.before(:all) do
    @base_dir = File.expand_path("..", File.dirname(__FILE__))
    @tmp_dir = File.expand_path("tmp", @base_dir)
    @css_file_path_1 = File.expand_path("test_1.css",  @tmp_dir)
    @css_file_path_2 = File.expand_path("test_2.css",  @tmp_dir)
    
    Dir.mkdir(@tmp_dir) unless File.exist?(@tmp_dir)
  end

  config.after(:all) do
    File.unlink(@css_file_path_1) if File.exist?(@css_file_path_1)
    File.unlink(@css_file_path_2) if File.exist?(@css_file_path_2)
    Dir.unlink(@tmp_dir) if File.exist?(@tmp_dir)
  end
end

def make_css(str, path)
  File.open(path, "w") { |f| f.write(str) }
end
