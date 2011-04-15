# -*- coding: utf-8 -*-
require "css_parser"
STDOUT.sync = true

class CssElement
  attr_accessor :css_selectors, :css_name
  REMOVE_METHODS = [:display] #remove to private method liset

  REMOVE_METHODS.each do |method_name|
    eval "private; def #{method_name}; super; end"
  end

  public

  def initialize(css_name)
    @css_name = css_name
    @css_selectors = []
  end

  def css_selectors
    @css_selectors ||= []
  end

  def css_real_selectors
    @css_real_selectors ||= {}
  end

  def empty?
    css_selectors.empty?
  end

  #
  # @todo: hoge-tara hoge_tara -> same name hoge_tara
  #
  def add_selector(name, real_name = nil)
    name_sym = name.kind_of?(String) ? name.gsub(/\-/, "_").to_sym : name
    css_selectors << name_sym
    css_real_selectors[name_sym] = real_name.nil? ? name : real_name
  end

  def has_selector?(other_selector)
    css_selectors.include?(other_selector)
  end

  def set_attributes(name, value)
    method_name = name.kind_of?(String) ? name.gsub(/\-/, "_").to_sym : name
    
    if value.kind_of?(String)
      if value =~ /,/
        return_value = value.gsub(/\"/, "").split(/,\s*/)
      else
        return_value = value.gsub(/\"/, "\\\"")
        return_value = "\"#{return_value}\""
      end
    else
      return_value = value
    end

    if respond_to?(method_name) or respond_to?("#{method_name}=")
      raise ArgumentError.new("already defined method: #{method_name}")
    end

    self.instance_eval "
      def #{method_name}
        @#{method_name} ||= #{return_value}
      end

      def #{method_name}=(value)
        @#{method_name} = #{return_value}
      end
"
      add_selector(method_name, name)
  end

  def same_entries(other)
    obj = self.class.new(css_name)

    css_selectors.each do |name|
      next unless other.has_selector?(name)
      next if send(name) != other.send(name)
      obj.set_attributes(css_real_selectors[name], send(name))
    end

    obj
  end

  def override_entries(other)
    entries = same_entries(other)
    return other if entries.empty?
    obj = self.class.new(css_name)

    other.css_selectors.each do |name|
      next unless self.respond_to?(name)
      next if other.send(name) == send(name)

      obj.set_attributes(other.css_real_selectors[name], 
                         other.send(name))
    end

    obj
  end

  def to_css
    str = "#{css_name} {\n"

    css_selectors.each do |name|
      real_name = css_real_selectors[name]
      value = send(name)

      if value.kind_of?(Array)
        str << "  #{real_name}: #{value.join(", ")};\n"
      else
        str << "  #{real_name}: #{value};\n"
      end
    end

    str << "}\n"
    str
  end

end

class CssHandler
  attr_reader :parser, :file_path
  
  def initialize(file_path)
    @file_path = file_path
    load_file!(file_path)
  end

  def parser
    @parser ||= CssParser::Parser.new
  end

  def objects
    @objects ||= {}
  end

  def find(name)
    parser.find_by_selector(name)
  end

  def get(name)
    @objects[name]
  end

  def has_name?(name)
    @objects.has_key?(name)
  end

  def same_elements(other)
    unless other.kind_of?(CssHandler)
      raise ArgumentError.new("argument must CssHandler Class") 
    end

    only_other_has_keys = other.objects.keys - objects.keys
    only_other_has = only_other_has_keys.collect{ |name| other.objects[name] }

    only_self_has_keys = objects.keys - other.objects.keys
    only_self_has = only_self_has_keys.collect{ |name| objects[name] }

    self_and_other_has = []

    objects.each do |name, self_object|
      if only_other_has_keys.include?(name) or 
          only_self_has_keys.include?(name)
        next 
      end

      other_object = other.get(name)
      same_entries = self_object.same_entries(other_object)

      next if same_entries.empty?
      self_and_other_has << same_entries
    end

    return self_and_other_has, only_self_has, only_other_has 
  end

  def override_entries(other)
    same_entries, _only_self_has, only_other_has = same_elements(other)
    override_entries = only_other_has.dup

    same_entries.each do |entry|
      self_entry = objects[entry.css_name]
      other_entry = other.objects[entry.css_name]
      override = self_entry.override_entries(other_entry)
      override_entries << override
    end

    override_entries.delete_if{ |e| e.css_selectors.empty? }
    override_entries
  end

  def override_entry_string(other)
    entries = override_entries(other)
    str = ""
    entries.each {|obj| str << obj.to_css << "\n"}
    str.chomp
  end

  def css_same_entry_string(other)
    same_entries, _only_self_has, _only_other_has = same_elements(other)

    str = ""
    same_entries.each {|obj| str << obj.to_css << "\n"}
    str.chomp
  end

  def print_css(css_list)
    css_list.each {|obj| puts obj.to_css << "\n"}
  end

  def parse_declarations(name, line)
    pairs = line.split(/;/)
    obj = CssElement.new(name)

    pairs.each do |paire_line|
      name, value = paire_line.split(/:/).collect{|e| e.strip }
      obj.set_attributes(name, value)
    end

    obj
  end

  def load_file!(filepath)
    parser.load_file!(filepath)
    
    parser.each_selector do |selector, declarations, specificity|
      objects[selector] =  parse_declarations(selector, declarations)
    end
  end

end
