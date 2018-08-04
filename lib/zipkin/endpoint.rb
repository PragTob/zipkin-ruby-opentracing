# frozen_string_literal: true

require 'socket'

module Zipkin
  class Endpoint
    LOCAL_IP = (
      Socket.ip_address_list.detect(&:ipv4_private?) ||
      Socket.ip_address_list.reverse.detect(&:ipv4?)
    ).ip_address

    module SpanKind
      SERVER = 'server'.freeze
      CLIENT = 'client'.freeze
      PRODUCER = 'producer'.freeze
      CONSUMER = 'consumer'.freeze
    end

    module PeerInfo
      SERVICE = :'peer.service'
      IPV4 = :'peer.ipv4'
      IPV6 = :'peer.ipv6'
      PORT = :'peer.port'

      def self.keys
        [SERVICE, IPV4, IPV6, PORT]
      end
    end

    def self.local_endpoint(service_name)
      new(service_name: service_name, ipv4: LOCAL_IP)
    end

    def self.remote_endpoint(span)
      tags = span.tags
      kind = tags[:'span.kind'] || SpanKind::SERVER

      case kind
      when SpanKind::SERVER, SpanKind::CLIENT
        return nil if (tags.keys & PeerInfo.keys).empty?

        new(
          service_name: tags[PeerInfo::SERVICE],
          ipv4: tags[PeerInfo::IPV4],
          ipv6: tags[PeerInfo::IPV6],
          port: tags[PeerInfo::PORT]
        )
      when SpanKind::PRODUCER, SpanKind::CONSUMER
        new(service_name: 'broker')
      else
        warn "Unkown span kind: #{kind}"
        nil
      end
    end

    def initialize(service_name: nil, ipv4: nil, ipv6: nil, port: nil)
      @service_name = service_name
      @ipv4 = ipv4
      @ipv6 = ipv6
      @port = port
    end

    attr_reader :service_name, :ipv4, :ipv6, :port
  end
end
