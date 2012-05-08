require 'spec_helper'
require 'sql_conditions'

describe SqlConditions do

  before(:each) do
    @where = SqlConditions.new
  end


  it 'should find the starting index of the helper method' do
    (@where.helper_index   "_is"         ).should == nil
    (@where.helper_index   "_is_"        ).should == nil
    (@where.helper_index  "x_is_"        ).should == nil
    (@where.helper_index "xx_is"         ).should == 2
    (@where.helper_index  "x_is"         ).should == 1
    (@where.helper_index  "x_are"        ).should == 1
    (@where.helper_index  "x_word_is"    ).should == 1
    (@where.helper_index  "x_word_begins").should == 1
    (@where.helper_index  "x_begins"     ).should == 1
    (@where.helper_index  "x_contains"   ).should == 1
    (@where.helper_index  "x_start_date" ).should == 1
    (@where.helper_index  "x_end_date"   ).should == 1
  end

  it 'should find the helper method and create a symbol' do
    (@where.helper_sym "xx_is",          2).should == :is
    (@where.helper_sym  "x_is",          1).should == :is
    (@where.helper_sym  "x_are",         1).should == :are
    (@where.helper_sym  "x_word_is",     1).should == :word_is
    (@where.helper_sym  "x_word_begins", 1).should == :word_begins
    (@where.helper_sym  "x_begins",      1).should == :begins
    (@where.helper_sym  "x_contains",    1).should == :contains
    (@where.helper_sym  "x_start_date",  1).should == :start_date
    (@where.helper_sym  "x_end_date",    1).should == :end_date
  end

  it 'should find the database column' do
    (@where.column_name "xx_is",          2).should == 'xx'
    (@where.column_name  "x_is",          1).should == 'x'
    (@where.column_name  "x_are",         1).should == 'x'
    (@where.column_name  "x_word_is",     1).should == 'x'
    (@where.column_name  "x_word_begins", 1).should == 'x'
    (@where.column_name  "x_begins",      1).should == 'x'
    (@where.column_name  "x_contains",    1).should == 'x'
    (@where.column_name  "x_start_date",  1).should == 'x'
    (@where.column_name  "x_end_date",    1).should == 'x'
  end

  it 'should find the helper method and create a symbol, after functions' do
    (@where.helper_sym "upper_xx_is",         8).should == :is
    (@where.helper_sym "lower_x_is",          7).should == :is
    (@where.helper_sym "upper_lower_x_is",   13).should == :is
    (@where.helper_sym "lower_upper_x_is",   13).should == :is
  end

  it 'should find database column after functions' do
    (@where.column_name "upper_xx_is",        8).should == 'xx'
    (@where.column_name "lower_x_is",         7).should == 'x'
    (@where.column_name "upper_lower_x_is",  13).should == 'x'
    (@where.column_name "lower_upper_x_is",  13).should == 'x'
  end

  it 'should find database functions' do
    (@where.functions "upper_xx_is",        8).should == {upper: true}
    (@where.functions "lower_x_is",         7).should == {lower: true}
    (@where.functions "upper_lower_x_is",  13).should == {lower: true, upper: true}
    (@where.functions "lower_upper_x_is",  13).should == {lower: true, upper: true}
    (@where.functions "lower_upper_x_is",  13).should == {upper: true, lower: true}
  end


  it 'is empty' do
    @where.to_s.should == '[]'
    true.should be_true
  end

  it 'should append sql' do
    @where << '1=2'
    @where.to_s.should == '["1=2"]'
  end

  it 'should filter on taxon_id' do
    @where.taxon_id_is 1 
    @where.to_s.should == '["taxon_id = ?", 1]'
  end

  it 'should filter where taxon_id is null' do
    @where.taxon_id_is 0 
    @where.to_s.should == '["taxon_id is null"]'
  end

  it 'should filter where taxon_id is null, 2' do
    @where.taxon_id_is "0" 
    @where.to_s.should == '["taxon_id is null"]'
  end

  it 'should filter on name' do
    @where.name_is 'name'
    @where.to_s.should == '["name = ?", "name"]'
  end

  it 'should find id' do
    @where.ids_are '1'
    @where.to_s.should == '["(ids = ?)", 1]'
  end

  it 'should find id list' do
    @where.ids_are '1-3'
    @where.to_s.should == '["((ids >= ? and ids <= ?))", 1, 3]'
  end

  it 'should filter by begins with' do
    @where.col_begins 1 
    @where.to_s.should == '["col like ? || \'%\'", 1]'
  end

  it 'should filter by contains' do
    @where.col_contains 1 
    @where.to_s.should == '["col like \'%\' || ? || \'%\'", 1]'
  end

  it 'should filter by word_is' do
    @where.col_word_is 1 
    @where.to_s.should == '["col like \'% \' || ? || \' %\'", 1]'
  end

  it 'should filter by word_begins' do
    @where.col_word_begins 1 
    @where.to_s.should == '["col like \'% \' || ? || \'%\'", 1]'
  end

  it 'should start by year' do
    @where.col_start_date '2000-2-3'
    @where.to_s.should == '["col >= ?", #<Date: 2000-02-03 ((2451578j,0s,0n),+0s,2299161j)>]'
  end

  it 'should end by year' do
    @where.col_end_date '2000-2-3'
    @where.to_s.should == '["col <= ?", #<Date: 2000-02-03 ((2451578j,0s,0n),+0s,2299161j)>]'
  end

  it 'should filter by lower(begins with)' do
    @where.lower_col_begins 1 
    @where.to_s.should == '["lower(col) like lower(? || \'%\')", 1]'
  end


  it 'should filter on 2 conditions: taxon_id and name' do
    @where.taxon_id_is 1 
    @where.name_is 'myname'
    @where.to_s.should == '["taxon_id = ? and name = ?", 1, "myname"]'
  end

  it 'should filter on 3 conditions' do
    @where << '1=2'
    @where << '3=4'
    @where.id_is '5'
    @where.to_s.should == '["1=2 and 3=4 and id = ?", "5"]'
  end


  it 'should ignore the "or" method call without a block' do
    @where.op :or
    @where << '1=2'
    @where.to_s.should == '["1=2"]'
  end

  it 'should ignore the "or" method call with an empty block' do
    @where.op :or do
    end
    @where << '1=2'
    @where.to_s.should == '["1=2"]'
  end

  it 'should put the single "or" condition in parends' do
    @where.op :or do
      @where << '1=2'
    end
    @where.to_s.should == '["(1=2)"]'
  end

  it 'should put the two "or" conditions in parends' do
    @where.op :or do 
      @where << '1=2'
      @where << '2=1'
    end
    @where.to_s.should == '["(1=2 or 2=1)"]'
  end

  it 'should handle a bunch of nested and/or conditions, and << method params' do
    @where.op :or do 
      @where.op :and do 
        @where.op :or
        @where.op :or do
        end
        @where.op :or do
          @where << '1=2'
          @where << '3=4'
          @where << '5=6'
        end
        @where << '7=8'
      end
      @where << '9=10'
      @where.<<('?=?', 11, 12)
    end
    @where.to_s.should == '["(((1=2 or 3=4 or 5=6) and 7=8) or 9=10 or ?=?)", 11, 12]'
  end

end

