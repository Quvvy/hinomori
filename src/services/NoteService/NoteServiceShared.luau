--!strict

export type SendNoteResult = {
	ok: boolean,
	reason: string?,
}

export type SendStrangerNoteResult = SendNoteResult
export type SendFriendNoteResult = SendNoteResult

local NoteServiceShared = {
	NOTE_TIER_STRANGER = "Stranger",
	NOTE_TIER_FRIEND = "Friend",

	SEND_REASON_SENT = "sent",
	SEND_REASON_OWNER_OFFLINE = "owner_offline",
	SEND_REASON_NOTES_DISABLED = "notes_disabled",
	SEND_REASON_BLOCKED = "blocked",
	SEND_REASON_DAILY_LIMIT = "daily_limit",
	SEND_REASON_LOCKER_FULL = "locker_full",
	SEND_REASON_SELF = "self",
	SEND_REASON_TOO_FAR = "too_far",
	SEND_REASON_INVALID_TEMPLATE = "invalid_template",
	SEND_REASON_NOT_FRIENDS = "not_friends",
	SEND_REASON_TEXT_EMPTY = "text_empty",
	SEND_REASON_TEXT_TOO_LONG = "text_too_long",
	SEND_REASON_FILTER_FAILED = "filter_failed",
	SEND_REASON_UNKNOWN = "unknown",
}

function NoteServiceShared.failure(reason: string): SendNoteResult
	return {
		ok = false,
		reason = reason,
	}
end

function NoteServiceShared.success(): SendNoteResult
	return {
		ok = true,
		reason = NoteServiceShared.SEND_REASON_SENT,
	}
end

return NoteServiceShared
