TODO
- IN-APP ACTIVITY MONITORING - DONE
- USER CURRENT APPOINTMENT LIST - DONE
- AI REDIRECTION LOGIC
- PAYMENT INTEGRATION
- CHANGE DOCTOR AVAILABILITY SCHEDULE IN DOCTOR SET UP WITH DYNAMIC DAY AND TIME SLOTS
- OAUTH INTEGRATION
- EMAIL VERIFICATION
- TEST VIDEO CALLING
- UPLOAD FILES TO SERVER
- UPLOAD PROFILE PIC


6/23/2025 - PUTAN
- filter only by verified doctors in the doctor list
- removed rebuilding ui of doctor list every time when selecting specialization
- MAJOR denormalization of doctor_information to user collection for performance improvement in almost EVERYTHING where doctor information is needed.

6/22/2025 - PUTAN
- Changed the specializations field to a dropdown in register doctor page
- Fixed the search_index not using the fullNameLowercase when registering doctor
- Included filtering using minFee and maxFee in the doctor list as well as searching by name
- added minFee and maxFee and medical history fields to the profile set up page
- filtered the profile setup page to not display minfee, maxfee, and medical history fields if the user is a doctor
- added schedule_picker
- added the availability schedule in the doctor profile set up to be time-based instead of morning, afternoon, evening...

6/21/2025 - PUTAN
- NotificationService for grouping activity-related funcs
- Recent activities in the dashboard
- message and appointment supported in the dashboard
- redirection to nurse joy ai chat in the dashboard

6/20/2025 - PUTAN
- USER CURRENT APPOINTMENT LIST
- REMOVED _generateChatRoomID and instead use the generateChatRoomID method from ChatListDB
- FIXED THE CHATROOM GENERATION WHEN USER SENDS MSG
- FIXED INCONSISTENT APP AND FIRESTORE DOC FIELD NAMES

