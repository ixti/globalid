require 'support/person_model'

RSpec.describe GlobalID::Identification do
  let(:model) { PersonModel.new :id => 1 }

  specify 'creates a Global ID from self' do
    expect(model.to_global_id).to eq GlobalID.create model
    expect(model.to_gid).to eq GlobalID.create model
  end

  specify 'creates a signed Global ID from self' do
    expect(model.to_signed_global_id).to eq SignedGlobalID.create model
    expect(model.to_sgid).to eq SignedGlobalID.create model
  end

  specify 'creates a signed Global ID with purpose ' do
    expect(model.to_signed_global_id :for => 'login')
      .to eq SignedGlobalID.create(model, :for => 'login')

    expect(model.to_sgid :for => 'login')
      .to eq SignedGlobalID.create(model, :for => 'login')
  end
end
