require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "CssHandler", :with => :new do
  before :all do
    @css_1 =<<EOF
body {
  overflow: hidden;
  font-family: Arial, Verdana, sans-serif;
  font-size: 12px;
  background-color: #333;
}

/* use iframe layout */
.iframe-body {
  overflow: hidden;
  font-family: Arial, Verdana, sans-serif;
  font-size: 12px;
  background-color: #111;
}
/* use iframe-black layout */
.iframe-body-black {
  overflow: hidden;
  font-family: Arial, Verdana, sans-serif;
  font-size: 15px;
  background-color: #333;
}

.not-overrided-class {
  background-color: #fff;
}
EOF

    @css_2 =<<EOF
body {
  overflow: hidden;
  font-family: Arial, Verdana, sans-serif;
  font-size: 12px;
  background-color: #333;
}

/* use iframe layout */
.iframe-body {
  overflow: hidden;
  font-family: Arial, Verdana, sans-serif;
  font-size: 12px;
  background-color: #222;
}
/* use iframe-black layout */
.iframe-body-black {
  overflow: hidden;
  font-family: Arial, Verdana, sans-serif;
  font-size: 13px;
  background-color: #333;
}

.overrided-class {
  background-color: #000;
}
EOF
    make_css(@css_1, @css_file_path_1)
    make_css(@css_2, @css_file_path_2)
  end

  before :each do
    @handler_1 = CssHandler.new(@css_file_path_1)
    @handler_2 = CssHandler.new(@css_file_path_2)
  end

  it "should create instance with filepath" do
    @handler_1.class.should == CssHandler
    @handler_2.class.should == CssHandler
  end

  it "should call method using element name" do
    obj = @handler_1.objects[".iframe-body-black"]
    obj.class.should == CssElement
    obj.overflow.should == "hidden"
    obj.font_family.should == ["Arial", "Verdana", "sans-serif"]
    obj.font_size.should == "15px"
    obj.background_color.should == "#333"

    obj2 = @handler_2.objects[".iframe-body-black"]
    obj2.font_size.should == "13px"
  end

  it "should create same css" do
    css_body = @handler_1.css_same_entry_string(@handler_2)
    css_body.should_not =~ /font-size: 13px/
    css_body.should_not =~ /font-size: 15px/
    css_body.should_not =~ /background-color: #111/
    css_body.should_not =~ /background-color: #222/

    css_body.should ==
"body {
  overflow: hidden;
  font-family: Arial, Verdana, sans-serif;
  font-size: 12px;
  background-color: #333;
}

.iframe-body {
  overflow: hidden;
  font-family: Arial, Verdana, sans-serif;
  font-size: 12px;
}

.iframe-body-black {
  overflow: hidden;
  font-family: Arial, Verdana, sans-serif;
  background-color: #333;
}
"
  end

  it "should create css diff" do
    css_body = @handler_1.override_entry_string(@handler_2)
    css_body.should ==
".overrided-class {
  background-color: #000;
}

.iframe-body {
  background-color: #222;
}

.iframe-body-black {
  font-size: 13px;
}
"

    css_body = @handler_2.override_entry_string(@handler_1)
    css_body.should ==
".not-overrided-class {
  background-color: #fff;
}

.iframe-body {
  background-color: #111;
}

.iframe-body-black {
  font-size: 15px;
}
"
  end

end
