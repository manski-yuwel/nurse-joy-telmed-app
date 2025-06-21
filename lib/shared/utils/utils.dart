// create search index for the user
List<String> createSearchIndex(String fullName) {
  final List<String> parts = fullName.split(' ');
  final List<String> nGrams = [];
  for (String part in parts) {
    nGrams.addAll(createNGrams(part));
  }
  return nGrams;
}

List<String> createNGrams(String part, {int minGram = 1, int maxGram = 10}) {
  final List<String> nGrams = [];
  for (int i = 1; i <= maxGram; i++) {
    if (i <= part.length) {
      nGrams.add(part.substring(0, i));
    }
  }
  return nGrams;
}

List<String> getSpecializations() {
  return [
    'Cardiologist',
    'Dermatologist',
    'Endocrinologist',
    'Family Physician',
    'Gastroenterologist',
    'General Surgeon',
    'Gynecologist',
    'Hematologist',
    'Internal Medicine',
    'Nephrologist',
    'Neurologist',
    'Obstetrician',
    'Oncologist',
    'Ophthalmologist',
    'Orthopedic Surgeon',
    'Otolaryngologist (ENT)',
    'Pediatrician',
    'Psychiatrist',
    'Pulmonologist',
    'Radiologist',
    'Rheumatologist',
    'Urologist'
  ];
}