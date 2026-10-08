extends Node
## Global signal bus. Systems talk to each other through these signals instead
## of holding references to each other.

# --- Messages -----------------------------------------------------------
signal message_added(thread_id: String, msg: Dictionary)
signal message_changed(thread_id: String, msg_id: String)
signal thread_typing(thread_id: String, who: String, typing: bool)
signal thread_read(thread_id: String)
signal choice_offered(thread_id: String)
signal choice_cleared(thread_id: String)
signal choice_made(thread_id: String, choice_id: String, option_index: int)
signal autotype_requested(thread_id: String, text: String)

# --- Calls --------------------------------------------------------------
signal call_incoming(call: Dictionary)
signal call_started(call: Dictionary)
signal call_line(who: String, text: String)
signal call_ended(call: Dictionary)
signal call_response(answered: bool)
signal call_hangup_requested

# --- Phone / apps -------------------------------------------------------
signal app_opened(app_id: String)
signal app_closed(app_id: String)
signal open_app_requested(app_id: String, params: Dictionary)
signal notification_posted(n: Dictionary)
signal lock_requested
signal unlocked
signal glitch_requested(intensity: float, duration: float)
signal vibrate_requested(count: int)
signal phone_state_changed            # battery, signal, location, settings...
signal content_changed(kind: String)  # "photos", "emails", "files", "notes", "contacts", "calls", "clues", "browser"
signal photo_changed(photo_id: String)
signal toast_requested(text: String)
signal screen_off_requested(duration: float)
signal restart_requested
signal reflection_requested

# --- Player investigation actions --------------------------------------
signal photo_viewed(photo_id: String)
signal page_visited(page_id: String)
signal searched(query: String)
signal clue_found(clue_id: String)
signal email_opened(email_id: String)
signal file_opened(file_id: String)
signal location_viewed(loc_id: String)
signal player_called(who: String)

# --- Narrative ----------------------------------------------------------
signal chapter_started(chapter_id: String)
signal chapter_ended(chapter_id: String)
signal ending_reached(ending_id: String)
signal deduction_requested
signal state_loaded
signal time_changed(unix: float)

# --- Meta ---------------------------------------------------------------
signal achievement_unlocked(id: String)
signal settings_changed
signal game_paused(paused: bool)
