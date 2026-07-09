--!strict

export type SessionPhase = "BusPrologue" | "School" | "AfterSchool"
export type FirstDayStep =
	"namedSelf"
	| "openedLocker"
	| "decoratedLocker"
	| "sentNote"
	| "sharedSnack"
	| "reachedAfterSchool"
	| "playedArcade"

return {
	PHASE_BUS_PROLOGUE = "BusPrologue" :: SessionPhase,
	PHASE_SCHOOL = "School" :: SessionPhase,
	PHASE_AFTER_SCHOOL = "AfterSchool" :: SessionPhase,

	DEFAULT_PHASE = "BusPrologue" :: SessionPhase,

	FIRST_DAY_STEP_NAMED_SELF = "namedSelf" :: FirstDayStep,
	FIRST_DAY_STEP_OPENED_LOCKER = "openedLocker" :: FirstDayStep,
	FIRST_DAY_STEP_DECORATED_LOCKER = "decoratedLocker" :: FirstDayStep,
	FIRST_DAY_STEP_SENT_NOTE = "sentNote" :: FirstDayStep,
	FIRST_DAY_STEP_SHARED_SNACK = "sharedSnack" :: FirstDayStep,
	FIRST_DAY_STEP_REACHED_AFTER_SCHOOL = "reachedAfterSchool" :: FirstDayStep,
	FIRST_DAY_STEP_PLAYED_ARCADE = "playedArcade" :: FirstDayStep,

	FIRST_DAY_STEPS = {
		"namedSelf" :: FirstDayStep,
		"openedLocker" :: FirstDayStep,
		"decoratedLocker" :: FirstDayStep,
		"sentNote" :: FirstDayStep,
		"sharedSnack" :: FirstDayStep,
		"reachedAfterSchool" :: FirstDayStep,
		"playedArcade" :: FirstDayStep,
	},
}
