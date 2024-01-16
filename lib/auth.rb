# frozen_string_literal: true

# Functions to get access token to FHIR server
module Auth
  # Print debug info while running a rake task for example
  # @param [Boolean] val true or false
  def self.verbose=(val)
    @verbose = val
  end

  # Create authentication JWT (Backend Service Authorization)
  # See https://hl7.org/fhir/uv/bulkdata/authorization/index.html#protocol-details
  # @param [Hash] fhir_srv_config Should include :token_endpoint (link)
  def self.create_jwt(fhir_srv_config)
    private_keys_file = ENV['SMART_SYS_APP_PRIVATE_KEYS_FILE'].presence || 'config/auth_private_jwks.json'
    # jwks hold multiple signing keys (private, includes public)
    jwks = JWT::JWK::Set.new(JSON.load_file(private_keys_file))
    # We use the last/newest jwk to sign our JWT
    # The public part of key is in a separate jwks that is also published at the FHIR server
    # In our case it is published at CernerCentral -> System Accounts
    jwk = jwks.to_a.last # we get the newest one if there are more
    raise 'No JWK signing key was found' unless jwk

    # jti: a nonce string value that uniquely identifies this authentication JWT
    # Store it so you can verify it later
    jti = SecureRandom.urlsafe_base64
    Rails.logger.debug "JTI: #{jti}"
    # claims:
    payload = {
      iss: ENV['SMART_SYS_APP_CLIENT_ID'],
      sub: ENV['SMART_SYS_APP_CLIENT_ID'],
      aud: fhir_srv_config[:token_endpoint],
      exp: 5.minutes.from_now.to_i,
      jti: jti
    }
    header_fields = {
      alg: jwk[:alg],
      kid: jwk[:kid],
      typ: 'JWT'
    }
    [JWT.encode(payload, jwk.signing_key, jwk[:alg], header_fields), jti]
  end

  # Obtaining an Access Token (Backend Service Authorization)
  # See https://hl7.org/fhir/uv/bulkdata/authorization/index.html#obtaining-an-access-token
  # @param [String] scope see https://hl7.org/fhir/uv/bulkdata/authorization/index.html#scopes
  def self.get_access_token(scope)
    fhir_base_url = ENV['FHIR_URL']
    fhir_srv_config = Auth.get_fhir_srv_config(fhir_base_url)
    signed_claims, jti = Auth.create_jwt(fhir_srv_config)
    # TODO: what we do with the JTI ??
    # How it will protect against replay attacks if it's only purpose is that the auth server
    # checks for its uniqueness?
    post_body = {
      scope: scope,
      grant_type: 'client_credentials',
      client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
      client_assertion: signed_claims
    }
    post_headers = {
      'Content-Type' => 'application/x-www-form-urlencoded'
    }
    if @verbose
      puts "Posting to get access token:\n" \
           "To: #{fhir_srv_config[:token_endpoint]}\n" \
           "Headers: #{post_headers.pretty_inspect}" \
           "Body: #{post_body.pretty_inspect}\n"
    end
    auth_resp = Faraday.post(fhir_srv_config[:token_endpoint],
                             post_body,
                             post_headers)
    puts "Token endpoint response: #{auth_resp.pretty_inspect}" if @verbose
    access_token = JSON.parse(auth_resp.body).with_indifferent_access
    valid_for_seconds = access_token[:expires_in] || 300
    access_token[:valid_until] = valid_for_seconds.seconds.from_now
    Rails.logger.debug '=' * 80
    Rails.logger.debug "Access token retrieved: #{Auth.access_token_safe_to_log(access_token).pretty_inspect}"
    access_token
  end

  # Retrieve Server Conformance with SMART Backend Services
  # This will call the server’s /.well-known/smart-configuration endpoint
  # We need this to get the token_endpoint for example
  # See https://hl7.org/fhir/uv/bulkdata/authorization/index.html#advertising-server-conformance-with-smart-backend-services
  # @param [String] fhir_base_url URL of FHIR server
  def self.get_fhir_srv_config(fhir_base_url)
    url = URI.join(fhir_base_url, '.well-known/smart-configuration')
    response = Faraday.get do |req|
      req.url url
      req.headers['Accept'] = 'application/json'
    end
    puts "FHIR server .well-known/smart-configuration response:\n#{response.pretty_inspect}" if @verbose
    raise "well-known/smart-configuration call failed with status #{response.status}" unless response.status == 200

    response_h = JSON.parse(response.body).with_indifferent_access
    puts "Response body:\n#{response_h.class}, #{response_h.pretty_inspect}" if @verbose
    response_h.slice(:token_endpoint, :authorization_endpoint, :jwks_uri)
  end

  # Creates a copy of the access token that can be logged
  # @param [Hash] access_token
  def self.access_token_safe_to_log(access_token)
    access_token_safe_to_log = access_token.deep_dup
    access_token_safe_to_log[:access_token] = "#{access_token_safe_to_log[:access_token][0..5]}..."
    access_token_safe_to_log
  end
end
