require 'support/person'
require 'support/person_model'

RSpec.describe GlobalID do
  specify 'value equality' do
    expect(GlobalID.new 'gid://app/model/id')
      .to eq(GlobalID.new 'gid://app/model/id')
  end

  specify 'invalid app name' do
    expect { GlobalID.app = '' }.to raise_error ArgumentError
    expect { GlobalID.app = 'blog_app' }.to raise_error ArgumentError
    expect { GlobalID.app = nil }.to raise_error ArgumentError
  end

  describe '#to_param' do
    let(:gid) { GlobalID.create Person.new 'id' }

    specify 'parsing' do
      expect(gid).to eq GlobalID.parse gid.to_param
    end

    specify 'finding' do
      found = GlobalID.find gid.to_param

      expect(found).to be_a gid.model_class
      expect(found.id).to eq gid.model_id
    end
  end

  describe 'creation' do
    let(:uuid)                  { '7ef9b614-353c-43a1-a203-ab2307851990' }
    let(:person_gid)            { GlobalID.create Person.new 5 }
    let(:person_uuid_gid)       { GlobalID.create Person.new uuid }
    let(:person_namespaced_gid) { GlobalID.create Person::Child.new 4 }
    let(:person_model_gid)      { GlobalID.create PersonModel.new :id => 1 }

    specify 'find' do
      expect(person_gid.find).to eq Person.find(person_gid.model_id)
      expect(person_uuid_gid.find).to eq Person.find(person_uuid_gid.model_id)
      expect(person_namespaced_gid.find).to eq Person::Child.find(person_namespaced_gid.model_id)
      expect(person_model_gid.find).to eq PersonModel.find(person_model_gid.model_id)
    end

    specify 'find with class' do
      expect(person_gid.find(:only => Person)).to eq Person.find(person_gid.model_id)
      expect(person_uuid_gid.find(:only => Person)).to eq Person.find(person_uuid_gid.model_id)
      expect(person_model_gid.find(:only => PersonModel)).to eq PersonModel.find(person_model_gid.model_id)
    end

    specify 'find with class no match' do
      expect(person_gid.find(:only => Hash)).to be nil
      expect(person_uuid_gid.find(:only => Array)).to be nil
      expect(person_namespaced_gid.find(:only => String)).to be nil
      expect(person_model_gid.find(:only => Float)).to be nil
    end

    specify 'find with subclass' do
      expect(person_namespaced_gid.find :only => Person)
        .to eq Person::Child.find person_namespaced_gid.model_id
    end

    specify 'find with subclass no match' do
      expect(person_namespaced_gid.find(:only => String)).to be nil
    end

    specify 'find with module' do
      expect(person_gid.find(:only => GlobalID::Identification))
        .to eq Person.find(person_gid.model_id)

      expect(person_uuid_gid.find(:only => GlobalID::Identification))
        .to eq Person.find(person_uuid_gid.model_id)

      expect(person_model_gid.find(:only => ActiveModel))
        .to eq PersonModel.find(person_model_gid.model_id)

      expect(person_namespaced_gid.find(:only => GlobalID::Identification))
        .to eq Person::Child.find(person_namespaced_gid.model_id)
    end

    specify 'find with module no match' do
      expect(person_gid.find(:only => Enumerable)).to be nil
      expect(person_uuid_gid.find(:only => Forwardable)).to be nil
      expect(person_namespaced_gid.find(:only => Base64)).to be nil
      expect(person_model_gid.find(:only => Enumerable)).to be nil
    end

    specify 'find with multiple class' do
      expect(person_gid.find(:only => [Fixnum, Person]))
        .to eq Person.find(person_gid.model_id)

      expect(person_uuid_gid.find(:only => [Fixnum, Person]))
        .to eq Person.find(person_uuid_gid.model_id)

      expect(person_model_gid.find(:only => [Float, PersonModel]))
        .to eq PersonModel.find(person_model_gid.model_id)

      expect(person_namespaced_gid.find(:only => [Person, Person::Child]))
        .to eq Person::Child.find(person_namespaced_gid.model_id)
    end

    specify 'find with multiple class no match' do
      expect(person_gid.find :only => [Fixnum, Numeric]).to be nil
      expect(person_uuid_gid.find :only => [Fixnum, String]).to be nil
      expect(person_model_gid.find :only => [Array, Hash]).to be nil
      expect(person_namespaced_gid.find :only => [String, Set]).to be nil
    end

    specify 'find with multiple module' do
      expect(person_gid.find :only => [Enumerable, GlobalID::Identification])
        .to eq Person.find person_gid.model_id
      expect(person_uuid_gid.find :only => [Bignum, GlobalID::Identification])
        .to eq Person.find person_uuid_gid.model_id
      expect(person_model_gid.find :only => [String, ActiveModel])
        .to eq PersonModel.find person_model_gid.model_id
      expect(person_namespaced_gid.find :only => [Integer, GlobalID::Identification])
        .to eq Person::Child.find person_namespaced_gid.model_id
    end

    specify 'find with multiple module no match' do
      expect(person_gid.find(:only => [Enumerable, Base64])).to be nil
      expect(person_uuid_gid.find(:only => [Enumerable, Forwardable])).to be nil
      expect(person_model_gid.find(:only => [Base64, Enumerable])).to be nil
      expect(person_namespaced_gid.find(:only => [Enumerable, Forwardable])).to be nil
    end

    specify 'as string' do
      expect(person_gid.to_s).to eq 'gid://bcx/Person/5'
      expect(person_uuid_gid.to_s).to eq "gid://bcx/Person/#{uuid}"
      expect(person_namespaced_gid.to_s).to eq 'gid://bcx/Person::Child/4'
      expect(person_model_gid.to_s).to eq 'gid://bcx/PersonModel/1'
    end

    specify 'as param' do
      expect(person_gid.to_param).to eq 'Z2lkOi8vYmN4L1BlcnNvbi81'
      expect(person_gid).to eq GlobalID.parse 'Z2lkOi8vYmN4L1BlcnNvbi81'

      expect(person_uuid_gid.to_param).to eq 'Z2lkOi8vYmN4L1BlcnNvbi83ZWY5YjYxNC0zNTNjLTQzYTEtYTIwMy1hYjIzMDc4NTE5OTA'
      expect(person_uuid_gid).to eq GlobalID.parse('Z2lkOi8vYmN4L1BlcnNvbi83ZWY5YjYxNC0zNTNjLTQzYTEtYTIwMy1hYjIzMDc4NTE5OTA')

      expect(person_namespaced_gid.to_param).to eq 'Z2lkOi8vYmN4L1BlcnNvbjo6Q2hpbGQvNA'
      expect(person_namespaced_gid).to eq GlobalID.parse('Z2lkOi8vYmN4L1BlcnNvbjo6Q2hpbGQvNA')

      expect(person_model_gid.to_param).to eq 'Z2lkOi8vYmN4L1BlcnNvbk1vZGVsLzE'
      expect(person_model_gid).to eq GlobalID.parse('Z2lkOi8vYmN4L1BlcnNvbk1vZGVsLzE')
    end

    specify 'as URI' do
      expect(person_gid.uri).to eq URI('gid://bcx/Person/5')
      expect(person_uuid_gid.uri).to eq  URI("gid://bcx/Person/#{uuid}")
      expect(person_namespaced_gid.uri).to eq  URI('gid://bcx/Person::Child/4')
      expect(person_model_gid.uri).to eq  URI('gid://bcx/PersonModel/1')
    end

    specify 'model id' do
      expect(person_gid.model_id).to eq '5'
      expect(person_uuid_gid.model_id).to eq uuid
      expect(person_namespaced_gid.model_id).to eq '4'
      expect(person_model_gid.model_id).to eq '1'
    end

    specify 'model name' do
      expect(person_gid.model_name).to eq 'Person'
      expect(person_uuid_gid.model_name).to eq 'Person'
      expect(person_namespaced_gid.model_name).to eq 'Person::Child'
      expect(person_model_gid.model_name).to eq 'PersonModel'
    end

    specify 'model class' do
      expect(person_gid.model_class).to be Person
      expect(person_uuid_gid.model_class).to be Person
      expect(person_namespaced_gid.model_class).to be Person::Child
      expect(person_model_gid.model_class).to be PersonModel
    end

    specify ':app option' do
      person_gid = GlobalID.create Person.new 5
      expect(person_gid.to_s).to eq 'gid://bcx/Person/5'

      person_gid = GlobalID.create(Person.new(5), :app => "foo")
      expect(person_gid.to_s).to eq 'gid://foo/Person/5'

      expect { GlobalID.create(Person.new(5), :app => nil) }
        .to raise_error ArgumentError
    end
  end

  describe 'custom params' do
    specify 'custom params' do
      gid = GlobalID.parse 'gid://bcx/Person/5?hello=world'
      expect(gid.params[:hello]).to eq 'world'
    end
  end
end
