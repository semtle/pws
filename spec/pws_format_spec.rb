require_relative '../lib/pws/format'

describe PWS::Format do
  describe '.read' do
    before(:all) do
      @correct          = "12345678\x01\x00data"
      @unknown_version  = "12345678\xfd\x00data"
      @wrong_identifier = "012345678\x01\x00data"
      @too_short1       = "12345678\x01"
      @too_short2       = "12345678"
      @legacy           = "data"
    end
    
    before(:each) do
      @options = {
        key: 'value',
      }
    end
    
    it 'delegates to the proper format reader if data is in correct format' do
      PWS::Format[1.0].should_receive(:read).with('data', @options)
      PWS::Format.read(@correct, @options)
    end
    
    it 'has takes a boolean legacy option as 2nd paramater that falls back to 0.9' do
      PWS::Format[0.9].should_receive(:read).with('data', @options)
      PWS::Format.read(@legacy, @options.merge(legacy: true))
    end
    
    it 'cannot read legacy files without legacy option' do
      proc{ PWS::Format.read(@legacy, @options) }.should raise_error(
        PWS::NoAccess
      )
    end
    
    it 'cannot read unknown versions and reports that' do
      proc{ PWS::Format.read(@unknown_version) }.should raise_error(
        PWS::NoAccess,
        "Format version 253.0 could not be found within the pws gem",
      )
    end
    
    it 'cannot read if identifier is unknown and reports that' do
      proc{ PWS::Format.read(@wrong_identifier) }.should raise_error(
        PWS::NoAccess,
        'Not a password file',
      )
    end
    
    it 'cannot read if given data is too short' do
      proc{ PWS::Format.read(@too_short1) }.should raise_error(
        PWS::NoAccess,
        'Password file not valid',
      )
      proc{ PWS::Format.read(@too_short2) }.should raise_error(
        PWS::NoAccess,
        'Password file not valid',
      )
    end
  end
  
  describe '.write' do
    before(:each) do
      @data     = 'some_data_to_be_written'
    end
    
    it 'delegates to the proper format writer, determined by options[:version], passing the data, deleting the version from the options hash' do
      options = { version: 1.0 }
      PWS::Format[1.0].should_receive(:write).with(@data, {})
      PWS::Format.write(@data, options)
    end
    
    it 'uses the current PWS::VERSION file format if no other is given' do
      PWS::Format[PWS::VERSION].should_receive(:write).with(@data, {})
      PWS::Format.write(@data, {})
    end
    
    it 'writes the identifier and version header' do
      PWS::Format.write(
        @data, { version: 1.0, password: '123' }
      )[0...10].should =~ "12345678\x01\x00"
    end
    
  end
  
  describe '.[]' do
    before(:all) do
      %w(V42_0 V42_1 V42_2).each{ |v| PWS::Format.const_set(v, v) }
    end
    
    it 'returns the proper version constant when specifing version as Array of Integers' do
      PWS::Format[[42,1]].should == 'V42_1'
    end
    
    it 'returns the proper version constant when specifing version with Integers' do
      PWS::Format[42, 1].should == 'V42_1'
    end
    
    it 'returns the proper version constant when specifing version as Array of Strings (to_i gets called)' do
      PWS::Format[["42e", "1<"]].should == 'V42_1'
    end
    
    it 'returns the proper version constant when specifing version with Strings (to_i gets called)' do
      PWS::Format["42e", "2!"].should == 'V42_2'
    end
    
    it 'returns the proper version constant when specifing version with a single String (split by .)' do
      PWS::Format["42.2"].should == 'V42_2'
    end
    
    it 'returns the proper version constant when specifing version with a single Float' do
      PWS::Format[42.1].should == 'V42_1'
    end
    
    it 'also returns the proper version constant if only major version is given' do
      PWS::Format[42].should == 'V42_0'
    end
    
    it 'also returns the proper version constant if only major version is given (String)' do
      PWS::Format[42].should == 'V42_0'
    end
    
    it 'really works for 1.0' do
      PWS::Format[1, 0].should == PWS::Format::V1_0
    end
    
    it 'it falls back to [0.9] for backward compatibility (nil given)' do
      PWS::Format[nil].should == PWS::Format::V0_9
    end
    
    it 'raises ArgumentError when called with wrong argument type' do
      proc{ PWS::Format[{$$ => $$}] }.should raise_error(
        ArgumentError,
        "Invalid version given",
      )
    end
    
    it 'raises ArgumentError when called with senseless argument' do
      proc{ PWS::Format[[]] }.should raise_error(
        ArgumentError,
        "Invalid version given",
      )
    end
    
    it 'raises PWS::NoAccess when version cannot be found' do
      proc{ PWS::Format[43, 1] }.should raise_error(
        PWS::NoAccess,
        "Format version 43.1 could not be found within the pws gem",
      )
    end
  end#[]
end