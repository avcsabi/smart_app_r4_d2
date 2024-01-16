json.extract! patient, :id, :name, :first_name, :last_name, :birth_date, :gender, :phone_number, :communication_language, :created_at, :updated_at
json.url patient_url(patient, format: :json)
