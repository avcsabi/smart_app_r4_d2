# frozen_string_literal: true
class FhirServices

  SCOPE = 'system/Patient.read system/AllergyIntolerance.read system/Procedure.read system/Condition.read system/Appointment.read system/Encounter.read system/FamilyMemberHistory.read system/Immunization.read system/Observation.read'
  FHIR_URL = ENV['FHIR_URL']

  # Print debug info while running a rake task for example
  # true or false
  attr_writer :verbose

  # Set access token from some source
  attr_writer :access_token

  def access_token?
    @access_token.present?
  end

  # Get access token
  # It caches the token in memory
  def access_token
    # invalidate token if expired
    if @access_token && @access_token[:valid_until] < Time.now
      Rails.logger.debug "Removing access token expired at #{@access_token[:valid_until]}"
      @access_token = nil
    end
    @access_token ||= Auth.get_access_token(SCOPE)
  end

  # Search for patients for example by name
  # @param [String] term Search term
  # @param [String] search_by for example :name
  def patient_search(search_by, term)
    url = URI.join(FHIR_URL, 'Patient')
    puts "Using access token: #{access_token[:access_token]}" if @verbose
    response = Faraday.get(url) do |req|
      req.params[search_by] = term
      req.headers['Accept'] = 'application/json'
      req.headers['Authorization'] = "Bearer #{access_token['access_token']}"
    end

    if response.status != 200
      puts "FHIR server Patient search response:\n#{response.pretty_inspect}" if @verbose
      raise "Patient search call failed with status #{response.status}"
    end

    results = JSON.parse(response.body).with_indifferent_access
    (results[:entry] || [])&.map do |p|
      patient = p[:resource]
      summary = {
        id: patient[:id],
        name: patient[:name]&.first&.[](:text),
        family: patient['name']&.first&.[]('family'),
        given: patient['name']&.first&.[]('given')&.join(' '),
        gender: patient['gender'],
        birth_date: patient['birthDate']&.to_date,
        phone_number: patient['telecom']&.first&.[](:value),
        communication_language: patient['communication']&.first&.[](:language)&.[](:text)
      }
      { raw: patient, summary: summary }
    end
  end

  # Get allergies by patient id
  # @param [String] patient_id Search term
  def allergy_intolerance_search(patient_id)
    url = URI.join(FHIR_URL, 'AllergyIntolerance')
    puts "Using access token: #{access_token[:access_token]}" if @verbose
    response = Faraday.get(url) do |req|
      req.params[:patient] = patient_id
      req.headers['Accept'] = 'application/json'
      req.headers['Authorization'] = "Bearer #{access_token['access_token']}"
    end

    puts "FHIR server AllergyIntolerance search response:\n#{response.pretty_inspect}" if @verbose
    if response.status != 200
      raise "AllergyIntolerance search call failed with status #{response.status}"
    end

    JSON.parse(response.body).with_indifferent_access
  end

  # Get encounters by patient id
  # @param [String] patient_id Search term
  def encounter_search(patient_id)
    url = URI.join(FHIR_URL, 'Encounter')
    puts "Using access token: #{access_token[:access_token]}" if @verbose
    response = Faraday.get(url) do |req|
      req.params[:patient] = patient_id
      req.headers['Accept'] = 'application/json'
      req.headers['Authorization'] = "Bearer #{access_token['access_token']}"
    end

    puts "FHIR server Encounter search response:\n#{response.pretty_inspect}" if @verbose
    if response.status != 200
      puts "FHIR server Encounter search response:\n#{response.pretty_inspect}"
      raise "Encounter search call failed with status #{response.status}"
    end

    results = JSON.parse(response.body).with_indifferent_access[:entry]&.map{ |item| item[:resource] } || []
    results = results.map do |item|
      summary = {
        id: item[:id],
        patient_id: patient_id,
        resource_type: item[:resourceType],
        status: item[:status],
        type: item[:type]&.first&.[](:text),
        service_type: item[:serviceType]&.[](:text),
        priority: item[:priority]&.[](:text),
        period_start: item[:period]&.[](:start)&.to_datetime,
        reason_code: item[:reasonCode]&.first&.[](:text),
        location: item[:location]&.first&.[](:location)&.[](:display),
        service_provider: item[:serviceProvider]&.[](:display),
      }
      { raw: item, summary: summary }
    end
    puts "Encounter found:\n#{results.pretty_inspect}" if @verbose
    results
  end
end
