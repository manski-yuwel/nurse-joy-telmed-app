import 'package:firebase_ai/firebase_ai.dart';


final aiResponseSchema = Schema.object(
  properties: {
    'specialization': Schema.string(),
    'response': Schema.string(),
  },
);