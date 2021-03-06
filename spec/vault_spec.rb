require 'spec_helper'

describe Vault do
    context 'configuration' do
        it 'can be passed via initialization' do
            expect { 
                v = Vault.new({
                    client_id: 'client_id',
                    client_secret: 'client_secret',
                    tenant: 'tenant'
                })
            }.not_to raise_error(ArgumentError)
        end

        it 'can pull from environment variables' do
            expect { v = Vault.new() }.not_to raise_error(ArgumentError)
        end
    end
end

# todo: These tests are too volatile. Shift to mocks
describe Vault::Secret do
    before(:each) do 
        @v = Vault.new()
    end

    context 'fetch' do
        it 'requires a vault and a path' do
            expect { Vault::Secret.fetch() }.to raise_error(ArgumentError)
            expect { Vault::Secret.fetch(@v) }.to raise_error(ArgumentError)
            expect { Vault::Secret.fetch(@v, 'test') }.not_to raise_error(ArgumentError)
        end

        it 'returns a hash of the secret' do
            s = Vault::Secret.fetch(@v, "/test/secret")
            expect(s).to be_a(Hash)

            expect(s['path']).to eq("test:secret")
            expect(s['data']).to be_a(Hash)
        end

        it 'raises `AccessDeniedException` if the secret is not found' do
            expect { Vault::Secret.fetch(@v, "/fake/secret") }.to raise_error(AccessDeniedException)
        end
    end
end

describe Vault::Role do
    before(:each) do 
        @v = Vault.new()
    end

    context 'fetch' do
        it 'requires a vault and a path' do
            expect { Vault::Role.fetch() }.to raise_error(ArgumentError)
            expect { Vault::Role.fetch(@v) }.to raise_error(ArgumentError)
            expect { Vault::Role.fetch(@v, 'test') }.not_to raise_error(ArgumentError)
        end

        it 'returns a hash of the role' do
            s = Vault::Role.fetch(@v, "test-role")
            expect(s).to be_a(Hash)
            expect(s['createdBy']).to eq("users:thy-one:adam@migusgroup.com")
        end

        it 'raises `AccessDeniedException` if the role is not found' do
            expect { Vault::Role.fetch(@v, "fake-role") }.to raise_error(AccessDeniedException)
        end
    end

end

describe Vault::Client do
    before(:each) do 
        @v = Vault.new()
    end

    let(:client) { Vault::Client.create(@v, 'test-role') }

    # Added this to supress a warning related to `.not_to raise_error`
    RSpec::Expectations.configuration.on_potential_false_positives = :nothing
    
    it 'create requires a role name' do
        expect { Vault::Client.create(@v)}.to raise_error(ArgumentError)
    end

    it 'fetch requires a vault and an id' do 
        expect { Vault::Client.fetch() }.to raise_error(ArgumentError)
        expect { Vault::Client.fetch(@v) }.to raise_error(ArgumentError)
        expect { Vault::Client.fetch(@v,'test') }.not_to raise_error(ArgumentError)
    end

    it 'fetch returns a client object' do
        test_client = Vault::Client.fetch(@v, client['clientId'])

        expect(test_client['clientId']).to eq(client['clientId'])
    end

    it 'fetch requires a vault and an id' do 
        expect { Vault::Client.delete() }.to raise_error(ArgumentError)
        expect { Vault::Client.delete(@v) }.to raise_error(ArgumentError)
        expect { Vault::Client.delete(@v,'test') }.not_to raise_error(ArgumentError)
    end

    it 'fetch removes the resource' do 
        Vault::Client.delete(@v, client['clientId'])

        expect { Vault::Client.fetch(@v, client['clientId']) }.to raise_error(ResourceNotFoundException)
    end
end