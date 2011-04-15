# -*- coding: utf-8 -*-

require "css_parser"

require "css_handler/element"

module CssHandler
  class Handler
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
      unless other.kind_of?(CssHandler::Handler)
        raise ArgumentError.new("argument must CssHandler::Handler Class") 
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
      obj = CssHandler::Element.new(name)
      
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
end
