json.extract! patient, :id, :name, :first_name, :last_name, :age, :gender, :height, :created_at, :updated_at
json.url patient_url(patient, format: :json)
