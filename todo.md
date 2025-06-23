TODO
- IN-APP ACTIVITY MONITORING - DONE
- USER CURRENT APPOINTMENT LIST - DONE
- AI REDIRECTION LOGIC
- PAYMENT INTEGRATION
- CHANGE DOCTOR AVAILABILITY SCHEDULE IN DOCTOR SET UP WITH DYNAMIC DAY AND TIME SLOTS - DONE
- OAUTH INTEGRATION
- EMAIL VERIFICATION
- TEST VIDEO CALLING
- UPLOAD FILES TO SERVER
- UPLOAD PROFILE PIC


6/23/2025 - PUTAN
- filter only by verified doctors in the doctor list
- removed rebuilding ui of doctor list every time when selecting specialization
- MAJOR denormalization of doctor_information to user collection for performance improvement in almost EVERYTHING where doctor information is needed.
- added ai redirection logic. doctors will be filtered based on specialization, minFee, and maxFee and scored. the best doctor will be returned and the user will be redirected to that doctor's page. we are using this rule-based scoring logic because we don't have enough data for onboard ML or DL so we are using this for now. we can then extend the scoring. has performance implications because we are looping over the filtered doctors and scoring them.
- added fallback logic for ai redirection. if no doctor is found, the user will be redirected to the doctor list with the filters applied.
- added quick consult button in the ai chat so that if the user chats and the ai responds with a specialization, the user can choose to use Quick Consult to use the last specialization response and be redirected.
- added ai response schema so that the AI can respond with a JSON containing the specialization and the response. we are also passing the specialization dropdown
- fixed the minFee and maxFee not being parsed to in int in the profile set up page. will still parse in the ai chat.
- added initial data in doctor list so that we can navigate to it from the ai chat with the passed filters applied to it.

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

