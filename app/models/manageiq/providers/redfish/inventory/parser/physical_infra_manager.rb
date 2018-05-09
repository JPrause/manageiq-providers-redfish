module ManageIQ::Providers::Redfish
  class Inventory::Parser::PhysicalInfraManager < Inventory::Parser
    def parse
      physical_servers
      physical_server_details
    end

    private

    def physical_servers
      collector.physical_servers.each do |s|
        server = persister.physical_servers.find_or_build(s["@odata.id"])
        server.assign_attributes(
          :type                   => "ManageIQ::Providers::Redfish::PhysicalInfraManager::PhysicalServer",
          :name                   => s["Id"],
          :health_state           => s["Status"]["Health"],
          :power_state            => s["PowerState"],
          :hostname               => s["HostName"],
          :product_name           => "dummy",
          :manufacturer           => s["Manufacturer"],
          :machine_type           => "dummy",
          :model                  => s["Model"],
          :serial_number          => s["SerialNumber"],
          :field_replaceable_unit => "dummy",
          :raw_power_state        => s["PowerState"],
          :vendor                 => "unknown",
          :location_led_state     => s["IndicatorLED"],
          :physical_rack_id       => 0
        )
        persister.computer_systems.find_or_build(server)
      end
    end

    def physical_server_details
      # TODO(tadeboro): There is no similar data in Redfish service, so
      # mapping will need to be quite sophisticated if we would like to get
      # more info into database.
      collector.physical_server_details.each do |d|
        server = persister.physical_servers.find_or_build(d[:server_id])
        details = persister.physical_server_details.find_or_build(server)
        details.assign_attributes(
          :contact          => "",
          :description      => "",
          :location         => get_location(d),
          :room             => "",
          :rack_name        => get_rack(d),
          :lowest_rack_unit => ""
        )
      end
    end

    def get_location(detail)
      [
        detail.dig("PostalAddress", "HouseNumber"),
        detail.dig("PostalAddress", "Street"),
        detail.dig("PostalAddress", "City"),
        detail.dig("PostalAddress", "Country")
      ].compact.join(", ")
    end

    def get_rack(detail)
      detail.dig("Placement", "Rack") || ""
    end
  end
end
