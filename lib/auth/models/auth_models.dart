// data model for the user
final user = {
  'email': '',
  'profile_pic': '',
  'first_name': '',
  'last_name': '',
  'full_name': '',
  'full_name_lowercase': '',
  'gender': '',
  'civil_status': '',
  'age': 0,
  'birthdate': null,
  'address': '',
  'phone_number': '',
  'role': 'user',
  'status_online': false,
  'is_setup': false,
  'search_index': [],
};

// data model for the user's health information
final healthInformation = {
  'height': 0,
  'weight': 0,
  'blood_type': '',
  'allergies': [],
  'medications': [],
  'other_information': '',
};

// data model for doctor information
final doctorData = {
  'specialization': '',
  'working_history': [],
  'license_number': '',
  'years_of_experience': 0,
  'education': [],
  'hospital_affiliation': [],
  'rating': 0,
  'num_of_ratings': 0,
  'availability_schedule': [],
  'consultation_fee': [],
  'is_verified': false,
};
