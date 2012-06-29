require 'chuck'
require 'openssl'
require 'tempfile'
require 'fileutils'

# adapted from webrick/ssl
module Chuck
  class SSL

    RSA = Chuck.root + 'certs/server.key'
    CA  = Chuck.root + 'certs/server.crt'

    attr_reader :rsa, :ca

    def self.certificate host
      @certs       ||= {}
      @certs[host] ||= new('C', 'AU', 'O', host, 'OU', host, 'CN', host)
    end

    def initialize *cn
      @rsa = OpenSSL::PKey::RSA.new(File.read(RSA))
      @ca  = OpenSSL::X509::Certificate.new(File.read(CA))

      @crt = Dir::Tmpname.create('chuck-crt') {}
      IO.write(@crt, create(cn.size == 1 ? cn.first : cn).to_pem)
      ObjectSpace.define_finalizer(self, method(:finalize))
    end

    def private_key_file
      RSA.to_s
    end

    def certificate_file
      @crt
    end

    def finalize *args
      FileUtils.rm_f(@crt)
    end

    private
      def create cn
        cn = cn.each_slice(2).entries
        OpenSSL::X509::Certificate.new.tap do |crt|
          crt.subject    = OpenSSL::X509::Name.new(cn)
          crt.issuer     = ca.subject
          crt.not_before = Time.now
          crt.not_after  = Time.now + 365 * 24 * 60 * 60
          crt.public_key = rsa.public_key
          crt.serial     = (Time.now.to_f * 100).to_i
          crt.version    = 3

          ef = OpenSSL::X509::ExtensionFactory.new
          ef.subject_certificate = crt
          ef.issuer_certificate  = ca
          crt.extensions = [
            ef.create_extension('basicConstraints', 'CA:TRUE', true),
            ef.create_extension('subjectKeyIdentifier', 'hash'),
          ]

          crt.sign rsa, OpenSSL::Digest::SHA1.new
        end
      end
  end # SSL
end # Chuck
