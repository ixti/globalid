require 'support/person'

RSpec.describe GlobalID::Locator do
  let(:model) { Person.new 'id' }
  let(:gid)   { model.to_gid }
  let(:sgid)  { model.to_sgid }

  def with_app(app)
    old_app, GlobalID.app = GlobalID.app, app
    yield
  ensure
    GlobalID.app = old_app
  end

  specify 'by GID' do
    found = GlobalID::Locator.locate gid

    expect(found).to be_a gid.model_class
    expect(found.id).to eq gid.model_id
  end

  specify 'by GID with `:only` restriction with match' do
    found = GlobalID::Locator.locate(gid, :only => Person)

    expect(found).to be_a gid.model_class
    expect(found.id).to eq gid.model_id
  end

  specify 'by GID with `:only` restriction with match subclass' do
    instance  = Person::Child.new
    gid       = instance.to_gid
    found     = GlobalID::Locator.locate(gid, :only => Person)

    expect(found).to be_a gid.model_class
    expect(found.id).to eq gid.model_id
  end

  specify 'by GID with `:only` restriction with no match' do
    found = GlobalID::Locator.locate(gid, :only => String)
    expect(found).to be nil
  end

  specify 'by GID with `:only` restriction by multiple types' do
    found = GlobalID::Locator.locate(gid, :only => [String, Person])

    expect(found).to be_a gid.model_class
    expect(found.id).to eq gid.model_id
  end

  specify 'by GID with `:only` restriction by module' do
    found = GlobalID::Locator.locate(gid, :only => GlobalID::Identification)

    expect(found).to be_a gid.model_class
    expect(found.id).to eq gid.model_id
  end

  specify 'by GID with `:only` restriction by module no match' do
    found = GlobalID::Locator.locate(gid, :only => Forwardable)
    expect(found).to be nil
  end

  specify 'by GID with `:only` restriction by multiple types w/module' do
    found = GlobalID::Locator.locate(gid, :only => [String, GlobalID::Identification])

    expect(found).to be_a gid.model_class
    expect(found.id).to eq gid.model_id
  end

  specify 'by many GIDs of one class' do
    models = [Person.new('1'), Person.new('2')]
    expect(GlobalID::Locator.locate_many models.map(&:to_gid)).to eq models
  end

  specify 'by many GIDs of mixed classes' do
    models = [Person.new('1'), Person::Child.new('1'), Person.new('2')]
    expect(GlobalID::Locator.locate_many models.map(&:to_gid)).to eq models
  end

  specify 'by many GIDs with only: restriction to match subclass' do
    gids  = [Person.new('1'), Person::Child.new('1'), Person.new('2')].map(&:to_gid)
    found = GlobalID::Locator.locate_many gids, :only => Person::Child

    expect(found).to eq [Person::Child.new('1')]
  end

  specify 'by SGID' do
    found = GlobalID::Locator.locate_signed sgid

    expect(found).to be_a sgid.model_class
    expect(found.id).to eq sgid.model_id
  end

  specify 'by SGID with only: restriction with match' do
    found = GlobalID::Locator.locate_signed(sgid, :only => Person)

    expect(found).to be_a sgid.model_class
    expect(found.id).to eq sgid.model_id
  end

  specify 'by SGID with only: restriction with match subclass' do
    instance  = Person::Child.new
    sgid      = instance.to_sgid
    found     = GlobalID::Locator.locate_signed(sgid, :only => Person)

    expect(found).to be_a sgid.model_class
    expect(found.id).to eq sgid.model_id
  end

  specify 'by SGID with only: restriction with no match' do
    found = GlobalID::Locator.locate_signed(sgid, :only => String)
    expect(found).to be nil
  end

  specify 'by SGID with only: restriction by multiple types' do
    found = GlobalID::Locator.locate_signed(sgid, :only => [String, Person])

    expect(found).to be_a sgid.model_class
    expect(found.id).to eq sgid.model_id
  end

  specify 'by SGID with only: restriction by module' do
    found = GlobalID::Locator.locate_signed(sgid, :only => GlobalID::Identification)

    expect(found).to be_a sgid.model_class
    expect(found.id).to eq sgid.model_id
  end

  specify 'by SGID with only: restriction by module no match' do
    found = GlobalID::Locator.locate_signed(sgid, :only => Enumerable)
    expect(found).to be nil
  end

  specify 'by SGID with only: restriction by multiple types w/module' do
    found = GlobalID::Locator.locate_signed(sgid, :only => [String, GlobalID::Identification])

    expect(found).to be_a sgid.model_class
    expect(found.id).to eq sgid.model_id
  end

  specify 'by many SGIDs of one class' do
    models = [Person.new('1'), Person.new('2')]
    expect(GlobalID::Locator.locate_many models.map(&:to_sgid)).to eq models
  end

  specify 'by many SGIDs of mixed classes' do
    models = [Person.new('1'), Person::Child.new('1'), Person.new('2')]
    expect(GlobalID::Locator.locate_many models.map(&:to_sgid)).to eq models
  end

  specify 'by many SGIDs with only: restriction to match subclass' do
    sgids = [Person.new('1'), Person::Child.new('1'), Person.new('2')].map(&:to_sgid)
    found = GlobalID::Locator.locate_many sgids, :only => Person::Child

    expect(found).to eq [Person::Child.new('1')]
  end

  specify 'by GID string' do
    found = GlobalID::Locator.locate gid.to_s

    expect(found).to be_a gid.model_class
    expect(found.id).to eq gid.model_id
  end

  specify 'by SGID string' do
    found = GlobalID::Locator.locate_signed sgid.to_s

    expect(found).to be_a sgid.model_class
    expect(found.id).to eq sgid.model_id
  end

  specify 'by many SGID strings with `:for` restriction to match purpose' do
    sgids = [
      Person.new('1').to_sgid(:for => 'adoption').to_s,
      Person::Child.new('1').to_sgid.to_s,
      Person::Child.new('2').to_sgid(:for => 'adoption').to_s
    ]

    expect(GlobalID::Locator.locate_many_signed(sgids, :for => 'adoption', :only => Person::Child))
      .to eq([Person::Child.new('2')])
  end

  specify 'by to_param encoding' do
    found = GlobalID::Locator.locate gid.to_param

    expect(found).to be_a gid.model_class
    expect(found.id).to eq gid.model_id
  end

  specify 'by non-GID returns nil' do
    expect(GlobalID::Locator.locate 'This is not a GID').to be nil
  end

  specify 'by non-SGID returns nil' do
    expect(GlobalID::Locator.locate_signed 'This is not a SGID').to be nil
  end

  specify 'by invalid GID URI returns nil' do
    expect(GlobalID::Locator.locate 'http://app/Person/1').to be nil
    expect(GlobalID::Locator.locate 'gid://Person/1').to be nil
    expect(GlobalID::Locator.locate 'gid://app/Person').to be nil
    expect(GlobalID::Locator.locate 'gid://app/Person/1/2').to be nil
  end

  specify 'use locator with block' do
    GlobalID::Locator.use :foo do |gid|
      :foo
    end

    with_app('foo') do
      expect(GlobalID::Locator.locate'gid://foo/Person/1').to be :foo
    end
  end

  specify 'use locator with class' do
    class BarLocator
      def locate(gid); :bar; end
    end

    GlobalID::Locator.use :bar, BarLocator.new

    with_app 'bar' do
      expect(GlobalID::Locator.locate'gid://bar/Person/1').to be :bar
    end
  end

  specify 'app locator is case insensitive' do
    GlobalID::Locator.use :insensitive do |gid|
      :insensitive
    end

    with_app 'insensitive' do
      expect(GlobalID::Locator.locate'gid://InSeNsItIvE/Person/1')
        .to be :insensitive
    end
  end

  specify 'locator name cannot have underscore' do
    expect { GlobalID::Locator.use('under_score') { |gid| 'will never be found' } }.to raise_error ArgumentError
  end

  specify 'by valid purpose returns right model' do
    instance    = Person.new
    login_sgid  = instance.to_signed_global_id(:for => 'login')

    found = GlobalID::Locator.locate_signed(login_sgid.to_s, :for => 'login')

    expect(found).to be_a login_sgid.model_class
    expect(found.id).to eq login_sgid.model_id
  end

  specify 'by invalid purpose returns nil' do
    instance   = Person.new
    login_sgid = instance.to_signed_global_id(:for => 'login')
    found      = GlobalID::Locator.locate_signed(login_sgid.to_s, :for => 'like_button')

    expect(found).to be nil
  end

  specify 'by many with one record missing leading to a raise' do
    gids = [
      Person.new('1').to_gid,
      Person.new(Person::HARDCODED_ID_FOR_MISSING_PERSON).to_gid
    ]

    expect { GlobalID::Locator.locate_many gids }.to raise_error RuntimeError
  end

  specify 'by many with one record missing not leading to a raise when ignoring missing' do
    gids = [
      Person.new('1').to_gid,
      Person.new(Person::HARDCODED_ID_FOR_MISSING_PERSON).to_gid
    ]

    expect { GlobalID::Locator.locate_many(gids, :ignore_missing => true) }
      .not_to raise_error
  end
end
