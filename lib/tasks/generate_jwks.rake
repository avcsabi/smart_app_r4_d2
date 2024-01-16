desc 'Generate jwks files in config folder with private and public ES384 keys to be used in FHIR server authentication'
task :generate_prv_and_pub_jwks do
  Rails.logger ||= Logger.new($stdout)
  # Part of: Registering a SMART Backend Service (communicating public keys)
  # See https://hl7.org/fhir/uv/bulkdata/authorization/index.html#registering-a-smart-backend-service-communicating-public-keys
  # After running the generator the following 2 files will be generated:
  # 1: private keys JWKs file, path+name indicated by ENV['SMART_SYS_APP_PRIVATE_KEYS_FILE'] or 'config/auth_private_jwks.json'
  # 2: public keys JWKs file, path+name indicated by ENV['SMART_SYS_APP_PRIVATE_KEYS_FILE'] or 'config/auth_public_jwks.json'
  # After generation copy the contents of the PUBLIC JWKs to https://cernercentral.com/system-accounts/
  # a) select app's account
  # b) in section 'JSON Web Key Set' -> Edit
  # c) select 'JSON' and paste PUBLIC JWKs, click Save
  puts 'Generating private and JWKs'
  private_keys_file = ENV['SMART_SYS_APP_PRIVATE_KEYS_FILE'].presence || 'config/auth_private_jwks.json'
  puts "Private keys will be saved to: #{private_keys_file}"
  public_keys_file = ENV['SMART_SYS_APP_PUBLIC_KEYS_FILE'].presence || 'config/auth_public_jwks.json'
  puts "Public keys will be saved to: #{public_keys_file}"

  # use OpenSSL::PKey::EC.builtin_curves to see list of 'curve' names to be used as param for generate
  # Find curve names (section 3.1 of RFC 7518): https://notes.salrahman.com/generate-es256-es384-es512-private-keys/
  # For ES384 curve name is: 'secp384r1'
  puts 'Generating and exporting private key...'
  ec = OpenSSL::PKey::EC.generate('secp384r1')
  kid = SecureRandom.urlsafe_base64
  desc_params = {
    kid: kid,
    use: 'sig',
    alg: 'ES384'
  }
  jwk_private = JWT::JWK.new(ec, desc_params)
  jwk_private_exported = jwk_private.export(include_private: true)
  puts "Generated private key jwk:\n#{jwk_private_exported.pretty_inspect}"
  # Add key to a new blank JSON Web Key Set
  # Todo: rotate keys in a set and publish public keys in TLS endpoint
  # In theory it is not required to store any of the keys excpet keeping them in memory and
  # serving the public keys to Cerner, to auth servers, etc and private keys to client app
  jwks_private_exported = JWT::JWK::Set.new(jwk_private).export(include_private: true).to_json
  puts "Generated private key jwks:\n#{jwks_private_exported}"
  File.write(private_keys_file, jwks_private_exported)
  puts 'Exporting public key...'
  jwk_public_exported = jwk_private.export(include_private: false)
  puts "Exported public key jwk:\n#{jwk_public_exported.pretty_inspect}"
  jwks_public_exported = JWT::JWK::Set.new(jwk_private).export(include_private: false).to_json
  puts "Generated public key jwks:\n#{jwks_public_exported}"
  File.write(public_keys_file, jwks_public_exported)
end
