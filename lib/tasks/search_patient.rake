# frozen_string_literal: true

desc "Search patient (test) Usage: 'VERBOSE=0 rake search_patient'"
task :search_patient do
  require 'auth'
  require 'fhir_services'

  Rails.logger ||= Logger.new($stdout)
  verbose = !%w[0 no n].include?(ENV['VERBOSE'].to_s.downcase)
  Auth.verbose = verbose
  fhir = FhirServices.new
  fhir.verbose = verbose
  search_by = :name
  term = 'Covid'
  puts "Searching for patient by #{search_by} using term '#{term}'"
  patients = fhir.patient_search(search_by, term)
  puts "Patient search results: #{patients.pretty_inspect}" if verbose
  if patients.blank?
    puts 'No patient found using the search criteria'
  else
    puts "Found #{patients.count} patients matching search criteria"
    patient = patients.first
    puts "First patient: #{patient.pretty_inspect}" if verbose
    puts 'First patient summary:'
    Pry::ColorPrinter.pp(patient[:summary])
    encounters = fhir.encounter_search(patient[:summary][:id])
    if encounters.blank?
      puts 'Patient has no encounters'
    else
      puts "Found #{encounters.count} encounters for patient #{patient[:summary][:name]} (#{patient[:summary][:id]})"
      encounters.each do |encounter|
        puts "\nEncounter from #{encounter[:summary][:period_start] || '?'}:"
        Pry::ColorPrinter.pp(encounter[:summary])
      end
    end

    puts "\nAccess token:"
    Pry::ColorPrinter.pp(fhir.access_token)
  end
end
