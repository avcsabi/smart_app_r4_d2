class ApplicationController < ActionController::Base
  before_action :init_fhir
  before_action :restore_access_token
  after_action :save_access_token

  protected

  # Access to FHIR server
  attr_reader :fhir

  def init_fhir
    @fhir = FhirServices.new
  end

  # Loads access token from the session
  def restore_access_token
    fhir.access_token = session[:access_token]&.with_indifferent_access
    Rails.logger.debug '=' * 80
    if fhir.access_token?
      Rails.logger.debug 'Access token loaded from session:'
      Rails.logger.debug Auth.access_token_safe_to_log(fhir.access_token).pretty_inspect
    else
      Rails.logger.debug 'No access token found in session'
    end
  end

  # Save current access token to session
  def save_access_token
    unless fhir.access_token?
      Rails.logger.debug '=' * 80
      Rails.logger.debug 'No access token, saved in session skipped!'
      return
    end

    session[:access_token] = fhir.access_token
    Rails.logger.debug '=' * 80
    Rails.logger.debug 'Access token saved in session:'
    Rails.logger.debug Auth.access_token_safe_to_log(fhir.access_token).pretty_inspect
  end
end
