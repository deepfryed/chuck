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

    def self.certificate subject
      @certs               ||= {}
      @certs[subject.to_s] ||= new(subject)
    end

    def initialize subject
      @rsa = OpenSSL::PKey::RSA.new(File.read(RSA))
      @ca  = OpenSSL::X509::Certificate.new(File.read(CA))

      @crt = Dir::Tmpname.create('chuck-crt') {}
      IO.write(@crt, create(subject).to_pem)
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
      def create subject
        OpenSSL::X509::Certificate.new.tap do |crt|
          crt.subject    = subject
          crt.issuer     = ca.subject
          crt.not_before = Time.now
          crt.not_after  = Time.now + 86_400 * 365
          crt.public_key = rsa.public_key
          crt.serial     = (Time.now.to_f * 100).to_i
          crt.version    = 3

          ef = OpenSSL::X509::ExtensionFactory.new
          ef.subject_certificate = crt
          ef.issuer_certificate  = ca

          crt.add_extension(ef.create_extension("keyUsage","digitalSignature", true))
          crt.add_extension(ef.create_extension("subjectKeyIdentifier","hash",false))
          crt.sign rsa, OpenSSL::Digest::SHA256.new
        end
      end
  end # SSL
end # Chuck
