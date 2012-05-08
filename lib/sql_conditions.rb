require 'date'

module SqlConditions

  def SqlConditions.new
    Where.new
  end

                              #
                              # Assemble printf style array of sql conditions.
                              # Skips conditions where the value is null
                              # Converts searches of "0" to "is null"
                              #
  class Where

    def initialize
      # TODO: use only arrays
      @sql       = nil
      @vars      = []
      @sql_stack = []
      @op_stack  = []
    end

                              # -----------------
                              # get current query
                              # -----------------
    def conditions
      w = []
      if @sql
        w << @sql
        w << @vars
        w.flatten!
      end
      w
    end

    def to_s
      conditions.to_s
    end


                              # ---------------
                              # add criteria
                              # ---------------

    def is col, val, opt
      if val && (val == "0" || val == 0)
        self << "#{col} is null"
      else
        if opt && opt[:lower]
          self.<< "lower(#{col}) = lower(?)", val
        elsif opt && opt[:upper]
          self.<< "upper(#{col}) = upper(?)", val
        else
          self.<< "#{col} = ?", val
        end
      end
      self
    end

    def are col, val, opt
      if val && (val == "0" || val == 0)
        self << "#{col} is null"
      else
        if val
          self.or do
            vals = val.split(/[,]/)
            vals.each do |v|
              if v
                range = v.split('-')
                if range.size == 1
                  self.<< "#{col} = ?", range[0].to_i
                elsif range.size == 2
                  self.and do
                    self.<< "#{col} >= ?", range[0].to_i
                    self.<< "#{col} <= ?", range[1].to_i
                  end
                end
              end
            end
          end
        end
      end
      self
    end

    def begins col, val, opt
      if val && (val == "0" || val == 0)
        self << "#{col} is null"
      else
        if opt && opt[:lower]
          self.<< "lower(#{col}) like lower(? || '%')", val
        elsif opt && opt[:upper]
          self.<< "upper(#{col}) like upper(? || '%')", val
        else
          self.<< "#{col} like ? || '%'", val
        end
      end
      self
    end

    def contains col, val, opt
      if val && (val == "0" || val == 0)
        self << "#{col} is null"
      else
        if opt && opt[:lower]
          self.<< "lower(#{col}) like lower('%' || ? || '%')", val
        elsif opt && opt[:upper]
          self.<< "upper(#{col}) like upper('%' || ? || '%')", val
        else
          self.<< "#{col} like '%' || ? || '%'", val
        end
      end
      self
    end

                              # Find a complete word, with a space on each side of it.
                              # ie: to find id's in a denormalized table
    def word_is col, val, opt
      if val && (val == "0" || val == 0)
        self << "#{col} is null"
      else
        if opt && opt[:lower]
          self.<< "lower(#{col}) like lower('% ' || ? || ' %')", val
        elsif opt && opt[:upper]
          self.<< "upper(#{col}) like upper('% ' || ? || ' %')", val
        else
          self.<< "#{col} like '% ' || ? || ' %'", val
        end
      end
      self
    end

                              # Find the start of a word, with a leading space.
                              # ie: to find scientific names
    def word_begins col, val, opt
      if val && (val == "0" || val == 0)
        self << "#{col} is null"
      else
        if opt && opt[:lower]
          self.<< "lower(#{col}) like lower('% ' || ? || '%')", val
        elsif opt && opt[:upper]
          self.<< "upper(#{col}) like upper('% ' || ? || '%')", val
        else
          self.<< "#{col} like '% ' || ? || '%'", val
        end
      end
      self
    end

                              # Find the minimum date value
    def start_date col, val, opt
      if val && (val == "0" || val == 0)
        self << "#{col} is null"
      else
        if val
          val.gsub!(/\//, '-')
          vals = val.split('-')
          y = vals[0]
          m = (vals.length > 1 && vals[1]) ? vals[1] : 1
          d = (vals.length > 2 && vals[2]) ? vals[2] : 1
          self.<<("#{col} >= ?", Date.new(y.to_i, m.to_i, d.to_i))
        end
      end
      self
    end

    def end_date col, val, opt
      if val && (val == "0" || val == 0)
        self << "#{col} is null"
      else
        if val
          val.gsub!(/\//, '-')
          vals = val.split('-')
          y = vals[0]
          m = (vals.length > 1 && vals[1]) ? vals[1] : 1
          d = (vals.length > 2 && vals[2]) ? vals[2] : 1
          self.<<("#{col} <= ?", Date.new(y.to_i, m.to_i, d.to_i))
        end
      end
      self
    end


    def <<(s, *a)
      if s
        op = @op_stack.last
        if op
          if @sql_stack.last
            @sql_stack[@sql_stack.size-1] = "#{@sql_stack.last} #{op.to_s} #{s}"
          else
            @sql_stack << s
          end
        else
          if @sql
            @sql << " and #{s}"
          else
            @sql = s
          end
        end
        @vars << a if a
      end
      self
    end


    def op sym, &block
      if block
        @sql_stack.push nil
        @op_stack.push sym

        block.call

                              # remove the and/or used within the block
        @op_stack.pop

                              # the block of conditions is ( parend-ed ) here
        sql = @sql_stack.pop
        if sql
          self << "(#{sql})"
        end
      end
    end

    def or &block
      if block
        self.op :or, &block
      else
        self.op :or
      end
    end

    def and &block
      if block
        self.op :and, &block
      else
        self.op :and
      end
    end




                              # ----------------------
                              # missing_method helpers
                              # ----------------------

                              # find starting index of the helper method name
    def helper_index s
      result = s.index /(_word_is$|_word_begins$)/
      result = s.index /(_is$|_are$|_begins$|_contains$|_start_date$|_end_date$)/ if result == nil
      result = nil if result == 0
      result
    end

                              # get name of helper to call, and convert to symbol
    def helper_sym s, i
      s = s[i+1..s.size-1]
      (s) ? s.to_sym : nil
    end

                              # get the name of the database column
    def column_name s, i
      result = s[0..i-1]
      re = Regexp.new(/(lower_|upper_)/)
      result.gsub!(re) { |s| '' }
      result
    end

                              # get functions to apply on the database column: upper/lower
    def functions s, i
      result = nil
      s = s[0..i-1]
      re = Regexp.new(/(lower_|upper_)/)
      s.gsub!(re) do |s|
        if s
          result = {} if ! result
          result[s.sub('_', '').to_sym] = true
        end
      end
      result
    end

                              # if the arg is a hash, then the value to pass to the helper
                              #   is stored in hash[:column_name_symbol]
    def method_value arg, sym
      result = nil
      case arg
      when ::Hash
        result = arg[sym.to_sym] if sym
      else
        result = arg
      end
      result
    end

    def method_missing(method_sym, *args, &block)
      method_name = method_sym.to_s
      i = helper_index method_name
      if i
        sym = helper_sym method_name, i
        col = column_name method_name, i
        opt = functions method_name, i
        val = method_value(args[0], col)

                              # Allow overriding the column name.
                              # Adds clarity for denormalized tables- the column names are different.
        col = args[1] if (args.size >= 2)

                              # If the options[key] is null, skip this where clause.
        send sym, col, val, opt if sym && col && val
      else
        super
      end

      self
    end
  end


                              # Split s to array
                              # remove ', ie: Wilson's becomes Wilsons
                              # removes parends and text within
                              #
  def self.tokenize s
    toks = nil
    if s
      t = String.new(s)
      t.downcase!
      t.gsub!("'", "")
      t.gsub!(/\(.*\)/, "")
      t.strip!
      toks = t.split
    end
    toks
  end


                              # hyphens => spaces

  def self.taxon_filter s
    s = taxon_filter! String.new(s) if s
    s
  end

  def self.taxon_filter! s
    if s
      s.gsub!(/-/, ' ')
      s.gsub!(/,/, ' ')
      s.gsub!(/  /, ' ')
      filter! s
    end
    s
  end


                              # generic filtering of unwanted charactors

  def self.filter s
    filter! String.new(s)
  end

  def self.filter! s
    s.downcase!
    s.gsub!(/, /, ' ')
    s.gsub!(/,/, ' ')
    s.gsub!(/'/, '')
    s.gsub!(/[\(\)\[\]]/, ' ')
    s.gsub!(/  /, ' ')
    s.gsub! /[`'\"~!@\#$\%^&*()\{\}+=_?\/<>,.;-]/, ''
    s
  end


                              # Add the html needed to highlight matching toks in text
                              #   Only colorize words that begin with the token, within the text
                              #
                              # text - text to display
                              # toks - string of [comma, space, hyphen] separated tokens
                              # xml  - Builder:XmlMarkup
  def self.colorize text, toks
    if  toks
                              # remove hyphens and commas,
                              # then create regular expression "or" of tokens, ie: tok1|tok2|tok3
      tokens = tokenize(taxon_filter!(toks))
      tok_expr = tokens.join("|")

      if tok_expr
        re = Regexp.new(/ (#{tok_expr})/i)
        text = " #{text}".gsub!(re) { |s| "#{s[0]}<span class='colorized'>#{s[1,s.length]}</span>" }
        text.strip! if text
      end
    end
    text = '' if ! text
    text.strip!
    text
  end
end

