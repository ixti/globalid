require 'timecop'

require 'active_support/core_ext/numeric/time'      # for Numeric#{hours,minutes}
require 'active_support/core_ext/date/calculations' # for Date#tomorrow

require 'support/person'

RSpec.describe SignedGlobalID do
  let(:person_sgid) { SignedGlobalID.create Person.new 5 }

  specify 'as string' do
    expect(person_sgid.to_s).to eq 'eyJnaWQiOiJnaWQ6Ly9iY3gvUGVyc29uLzUiLCJwdXJwb3NlIjoiZGVmYXVsdCIsImV4cGlyZXNfYXQiOm51bGx9--04a6f59140259756b22008c8c0f76ea5ed485579'
  end

  specify 'model id' do
    expect(person_sgid.model_id).to eq "5"
  end

  specify 'model class' do
    expect(person_sgid.model_class).to eq Person
  end

  specify 'value equality' do
    expect(SignedGlobalID.create(Person.new(5))).to eq SignedGlobalID.create(Person.new(5))
  end

  specify 'value equality with an unsigned id' do
    expect(GlobalID.create(Person.new(5))).to eq SignedGlobalID.create(Person.new(5))
  end

  specify 'to param' do
    expect(person_sgid.to_param).to eq person_sgid.to_s
  end

  describe 'verifier' do
    let!(:person_sgid) { SignedGlobalID.create Person.new 5 }

    def with_default_verifier(verifier)
      original, SignedGlobalID.verifier = SignedGlobalID.verifier, verifier
      yield
    ensure
      SignedGlobalID.verifier = original
    end

    specify 'parse raises when default verifier is nil' do
      gid = person_sgid.to_s

      with_default_verifier nil do
        expect { SignedGlobalID.parse(gid) }.to raise_error ArgumentError
      end
    end

    specify 'create raises when default verifier is nil' do
      with_default_verifier nil do
        expect { SignedGlobalID.create(Person.new(5)) }
          .to raise_error ArgumentError
      end
    end

    specify 'create accepts a :verifier' do
      with_default_verifier nil do
        expected = SignedGlobalID.create(Person.new(5), :verifier => VERIFIER)
        expect(person_sgid).to eq expected
      end
    end

    specify 'new accepts a :verifier' do
      with_default_verifier nil do
        expected = SignedGlobalID.new(Person.new(5).to_gid.uri, :verifier => VERIFIER)
        expect(person_sgid).to eq expected
      end
    end
  end

  describe 'purpose' do
    let(:login_sgid) { SignedGlobalID.create(Person.new(5), :for => 'login') }

    specify 'sign with purpose when :for is provided' do
      expect(login_sgid.to_s).to eq 'eyJnaWQiOiJnaWQ6Ly9iY3gvUGVyc29uLzUiLCJwdXJwb3NlIjoibG9naW4iLCJleHBpcmVzX2F0IjpudWxsfQ==--4b9630f3a1fb3d7d6584d95d4fac96433ec2deef'
    end

    specify 'sign with default purpose when no :for is provided' do
      sgid          = SignedGlobalID.create(Person.new(5))
      default_sgid  = SignedGlobalID.create(Person.new(5), :for => "default")

      expect(sgid.to_s).to eq 'eyJnaWQiOiJnaWQ6Ly9iY3gvUGVyc29uLzUiLCJwdXJwb3NlIjoiZGVmYXVsdCIsImV4cGlyZXNfYXQiOm51bGx9--04a6f59140259756b22008c8c0f76ea5ed485579'
      expect(default_sgid).to eq sgid
    end

    specify 'create accepts a :for' do
      expected = SignedGlobalID.create(Person.new(5), :for => "login")
      expect(login_sgid).to eq expected
    end

    specify 'new accepts a :for' do
      expected = SignedGlobalID.new(Person.new(5).to_gid.uri, :for => 'login')
      expect(login_sgid).to eq expected
    end

    specify 'parse returns nil when purpose mismatch' do
      sgid = login_sgid.to_s
      expect(SignedGlobalID.parse sgid).to be nil
      expect(SignedGlobalID.parse sgid, :for => 'like_button').to be nil
    end

    specify 'equal only with same purpose' do
      expected        = SignedGlobalID.create(Person.new(5), :for => 'login')
      like_sgid       = SignedGlobalID.create(Person.new(5), :for => 'like_button')
      no_purpose_sgid = SignedGlobalID.create(Person.new(5))

      expect(login_sgid).to eq expected
      expect(login_sgid).to_not eq like_sgid
      expect(login_sgid).to_not eq no_purpose_sgid
    end
  end

  describe 'expiration' do
    let(:uri) { Person.new(5).to_gid.uri }

    def with_expiration_in(expires_in)
      old_expires, SignedGlobalID.expires_in = SignedGlobalID.expires_in, expires_in
      yield
    ensure
      SignedGlobalID.expires_in = old_expires
    end

    specify 'expires_in defaults to class level expiration' do
      with_expiration_in 1.hour do
        encoded_sgid = SignedGlobalID.new(uri).to_s

        Timecop.travel 59.minutes do
          expect(SignedGlobalID.parse encoded_sgid).to be_truthy
        end

        Timecop.travel 61.minutes do
          expect(SignedGlobalID.parse encoded_sgid).not_to be_truthy
        end
      end
    end

    specify 'passing in expires_in overrides class level expiration' do
      with_expiration_in 1.hour do
        encoded_sgid = SignedGlobalID.new(uri, expires_in: 2.hours).to_s

        Timecop.travel 1.hour do
          expect(SignedGlobalID.parse encoded_sgid).to be_truthy
        end

        Timecop.travel 2.hour + 3.seconds do
          expect(SignedGlobalID.parse encoded_sgid).not_to be_truthy
        end
      end
    end

    specify 'passing expires_in less than a second is not expired' do
      Timecop.freeze do
        encoded_sgid = SignedGlobalID.new(uri, :expires_in => 1.second).to_s

        Timecop.travel 0.5.second do
          expect(SignedGlobalID.parse encoded_sgid).to be_truthy
        end

        Timecop.travel 2.seconds do
          expect(SignedGlobalID.parse encoded_sgid).not_to be_truthy
        end
      end
    end

    specify 'passing expires_in nil turns off expiration checking' do
      with_expiration_in 1.hour do
        encoded_sgid = SignedGlobalID.new(uri, :expires_in => nil).to_s

        Timecop.travel 1.hour do
          expect(SignedGlobalID.parse encoded_sgid).to be_truthy
        end

        Timecop.travel 2.hours do
          expect(SignedGlobalID.parse encoded_sgid).to be_truthy
        end
      end
    end

    specify 'passing expires_at sets expiration date' do
      date = Date.today.end_of_day
      sgid = SignedGlobalID.new(uri, :expires_at => date)

      expect(sgid.expires_at).to eq date

      Timecop.travel 1.day do
        expect(SignedGlobalID.parse sgid.to_s).not_to be_truthy
      end
    end

    specify 'passing nil expires_at turns off expiration checking' do
      with_expiration_in 1.hour do
        encoded_sgid = SignedGlobalID.new(uri, :expires_at => nil).to_s

        Timecop.travel 4.hours do
          expect(SignedGlobalID.parse encoded_sgid).to be_truthy
        end
      end
    end

    specify 'passing expires_at overrides class level expires_in' do
      with_expiration_in 1.hour do
        date = Date.tomorrow.end_of_day
        sgid = SignedGlobalID.new(uri, :expires_at => date)

        expect(sgid.expires_at).to eq date

        Timecop.travel 2.hours do
          expect(SignedGlobalID.parse sgid.to_s).to be_truthy
        end
      end
    end

    specify 'favor expires_at over expires_in' do
      sgid = SignedGlobalID.new(uri, {
        :expires_at => Date.tomorrow.end_of_day,
        :expires_in => 1.hour
      })

      Timecop.travel 1.hour do
        expect(SignedGlobalID.parse sgid.to_s).to be_truthy
      end
    end
  end
end
