require 'support/person'

RSpec.describe URI::GID do
  let(:gid_string)  { 'gid://bcx/Person/5' }
  let(:gid)         { URI::GID.parse gid_string }

  specify 'parsed' do
    expect(gid.app).to eq 'bcx'
    expect(gid.model_name).to eq 'Person'
    expect(gid.model_id).to eq '5'
  end

  specify 'new returns invalid gid when not checking' do
    expect(URI::GID.new(*URI.split('gid:///'))).to be_truthy
  end

  specify 'create' do
    model = Person.new '5'
    expect(URI::GID.create('bcx', model).to_s).to eq gid_string
  end

  specify 'build' do
    from_array = URI::GID.build(['bcx', 'Person', '5', nil])
    expect(from_array).to be_truthy

    from_hash = URI::GID.build(app: 'bcx', model_name: 'Person', model_id: '5', params: nil)
    expect(from_hash).to be_truthy

    expect(from_array).to eq from_hash
  end

  specify 'build with wrong ordered array creates a wrong ordered gid' do
    wrong_gid = URI::GID.build(['Person', '5', 'bcx', nil]).to_s
    expect(wrong_gid).not_to eq gid_string
  end

  specify 'as String' do
    expect(gid.to_s).to eq gid_string
  end

  specify 'equal' do
    expect(gid).to eq URI::GID.parse gid_string
    expect(gid).to_not eq URI::GID.parse 'gid://bcxxx/Persona/1'
  end

  describe 'validation' do
    def assert_invalid_component(uri)
      expect { URI::GID.parse(uri) }.to raise_error URI::InvalidComponentError
    end

    def assert_bad_uri(uri)
      expect { URI::GID.parse(uri) }.to raise_error URI::BadURIError
    end

    specify 'missing app' do
      assert_invalid_component 'gid:///Person/1'
    end

    specify 'missing path' do
      assert_invalid_component 'gid://bcx/'
    end

    specify 'missing model id' do
      assert_invalid_component 'gid://bcx/Person'
    end

    specify 'too many model ids' do
      assert_invalid_component 'gid://bcx/Person/1/2'
    end

    specify 'empty' do
      assert_invalid_component 'gid:///'
    end

    specify 'invalid schemes' do
      assert_bad_uri 'http://bcx/Person/5'
      assert_bad_uri 'gyd://bcx/Person/5'
      assert_bad_uri '//bcx/Person/5'
    end
  end

  describe 'app validation' do
    def assert_invalid_app(value)
      expect { URI::GID.validate_app(value) }.to raise_error ArgumentError
    end

    specify 'nil or blank apps are invalid' do
      assert_invalid_app nil
      assert_invalid_app ''
    end

    specify 'apps containing non alphanumeric characters are invalid' do
      assert_invalid_app 'foo/bar'
      assert_invalid_app 'foo:bar'
      assert_invalid_app 'foo_bar'
    end

    specify 'app with hyphen is allowed' do
      expect(URI::GID.validate_app 'foo-bar').to eq 'foo-bar'
    end
  end

  describe 'params' do
    let(:gid) { URI::GID.create('bcx', Person.find(5), :hello => 'world') }

    specify 'indifferent key access' do
      expect(gid.params[:hello]).to eq 'world'
      expect(gid.params['hello']).to eq 'world'
    end

    specify 'integer option' do
      gid = URI::GID.build(['bcx', 'Person', '5', :integer => 20])
      expect(gid.params[:integer]).to eq '20'
    end

    specify 'multi value params returns last value' do
      gid = URI::GID.build(['bcx', 'Person', '5', :multi => %w(one two)])
      expect(gid.params).to eq 'multi' => 'two'
    end

    specify 'as String' do
      expect(gid.to_s).to eq 'gid://bcx/Person/5?hello=world'
    end

    specify 'immutable params' do
      gid.params[:param] = 'value'
      expect(gid.to_s).not_to eq 'gid://bcx/Person/5?hello=world&param=value'
    end
  end
end
