--!strict

export type StudentProfile = {
	displayName: string,
	year: number,
	transferStyle: string,
	hasCompletedTransferSetup: boolean,
}

export type LockerNotesSettings = {
	strangerNotesEnabled: boolean,
	maxVisibleStrangerNotes: number,
}

export type LockerDecorEntry = {
	itemId: string,
	slotId: string,
}

export type StrangerNoteEntry = {
	templateId: string,
	senderUserId: number,
	sentDayKey: string,
}

export type FriendNoteEntry = {
	text: string,
	senderUserId: number,
	sentDayKey: string,
}

export type PlayerProfile = {
	studentProfile: StudentProfile,
	assignedLockerId: string,
	lockerDecor: { LockerDecorEntry },
	lockerNotesSettings: LockerNotesSettings,
	strangerNotes: { StrangerNoteEntry },
	friendNotes: { FriendNoteEntry },
	blockedNoteSenderUserIds: { number },
	arcadeTickets: number,
}

local PROFILE_TEMPLATE: PlayerProfile = {
	studentProfile = {
		displayName = "Student",
		year = 1,
		transferStyle = "",
		hasCompletedTransferSetup = false,
	},
	assignedLockerId = "",
	lockerDecor = {},
	lockerNotesSettings = {
		strangerNotesEnabled = true,
		maxVisibleStrangerNotes = 5,
	},
	strangerNotes = {},
	friendNotes = {},
	blockedNoteSenderUserIds = {},
	arcadeTickets = 0,
}

return {
	PROFILE_TEMPLATE = PROFILE_TEMPLATE,
}
