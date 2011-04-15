# -*- coding: utf-8 -*-

module CssHandler
  class Element
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
        end"

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
end
