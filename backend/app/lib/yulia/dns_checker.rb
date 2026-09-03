require "resolv"

module Yulia
  # Checks that a domain actually points at this server before the user is told
  # their site is live.
  #
  # Getting this wrong is the single most common way a self-hosted site fails:
  # the A record is missing or still pointing somewhere else, Caddy cannot get
  # a certificate, and the browser shows a security warning with no explanation.
  # Answering the question up front turns that into a sentence the user can act on.
  module DnsChecker
    Result = Struct.new(:ok?, :addresses, :expected, :error, keyword_init: true)

    TIMEOUT = 5

    class << self
      def check(host, expected_ip: server_ip)
        addresses = resolve(host)

        if addresses.empty?
          return Result.new(ok?: false, addresses: [], expected: expected_ip,
                            error: :no_record)
        end

        if expected_ip.blank?
          # Without knowing our own address there is nothing to compare against;
          # say so rather than claiming success.
          return Result.new(ok?: false, addresses: addresses, expected: nil,
                            error: :unknown_server_ip)
        end

        if addresses.include?(expected_ip)
          Result.new(ok?: true, addresses: addresses, expected: expected_ip)
        else
          Result.new(ok?: false, addresses: addresses, expected: expected_ip,
                     error: :points_elsewhere)
        end
      end

      def resolve(host)
        Resolv::DNS.open do |dns|
          dns.timeouts = TIMEOUT
          v4 = dns.getresources(host, Resolv::DNS::Resource::IN::A).map { |r| r.address.to_s }
          v6 = dns.getresources(host, Resolv::DNS::Resource::IN::AAAA).map { |r| r.address.to_s }
          v4 + v6
        end
      rescue Resolv::ResolvError, Resolv::ResolvTimeout, IOError, SystemCallError
        []
      end

      # This server's address as the outside world sees it. Asking an external
      # service is the only reliable answer behind NAT, and the result is cached
      # because it does not change while the process lives.
      def server_ip
        @server_ip ||= ENV["SERVER_IP"].presence || discover_server_ip
      end

      private

        def discover_server_ip
          require "net/http"

          uri = URI("https://api.ipify.org")
          response = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                                     open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
            http.get(uri.path)
          end
          response.body.to_s.strip.presence
        rescue StandardError => e
          Rails.logger.warn("[yulia] could not determine the server's public address: #{e.message}")
          nil
        end
    end
  end
end
