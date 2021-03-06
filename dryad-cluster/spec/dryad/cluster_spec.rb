RSpec.describe Dryad::Cluster do
  before do
    config = OpenStruct.new({
      consul: { host: "127.0.0.1", port: 8500 },
      namespace: "growing-crm",
      group: "staging",
      registry: "Dryad::Consul::ServiceRegistry"
    })
    Dryad::Consul.configure_consul(config)
    Dryad::Cluster.configuration = config

    @portal = Dryad::Core::Portal.new(
      schema: Dryad::Core::Schema::HTTP,
      port: 3000,
      pattern: '/*',
      non_certifications: ['/*']
    )
    @service = Dryad::Consul::Service.new(
      name: 'rails',
      address: '127.0.0.1',
      group: 'staging',
      portals: [@portal],
      priority: 10,
      load_balancing: [Dryad::Core::LoadBalancing::URL_HASH]
    )
  end

  it "has a version number" do
    expect(Dryad::Cluster::VERSION).not_to be nil
  end

  it "rounds robin" do
    registry = Dryad::Consul::ServiceRegistry.instance
    registry.register(@service)
    service_instance = Dryad::Cluster.round_robin(
      Dryad::Core::Schema::HTTP,
      @service.name
    )
    expect(service_instance.name).to eq(@service.name)
    expect(service_instance.address).to eq(@service.address)
    registry.deregister(@service)
  end
end
