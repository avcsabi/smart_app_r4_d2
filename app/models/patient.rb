class Patient < ApplicationRecord
  attr_reader :details

  # @param [String] search_term search term sent to FHIR to search by name
  # @param [FhirServices] fhir
  def self.search_fhir(fhir, search_term)
    patients = fhir.patient_search(:name, search_term)

    patients.map do |patient_hash|
      patient_hash = patient_hash[:summary]
      patient = Patient.find_or_initialize_by(id: patient_hash[:id])
      patient.id = patient_hash[:id]
      patient.name = patient_hash[:name]
      patient.first_name = patient_hash[:given]
      patient.last_name = patient_hash[:family]
      patient.gender = patient_hash[:gender]
      patient.birth_date = patient_hash[:birth_date]
      patient.phone_number = patient_hash[:phone_number]
      patient.communication_language = patient_hash[:communication_language]
      patient.save!
      patient
    end
  end

  # Load encounters and/or other details of this patient
  def load_details(fhir)
    @details ||= {}
    @details[:encounters] = fhir.encounter_search(id.to_s)
  end
end
