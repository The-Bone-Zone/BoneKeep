// teleatom: atom to teleport
// destination: destination to teleport to
// precision: teleport precision (0 is most precise, the default)
// effectin: effect to show right before teleportation
// effectout: effect to show right after teleportation
// asoundin: soundfile to play before teleportation
// asoundout: soundfile to play after teleportation
// forceMove: if false, teleport will use Move() proc (dense objects will prevent teleportation)
// no_effects: disable the default effectin/effectout of sparks
// forced: whether or not to ignore no_teleport
/proc/do_teleport(atom/movable/teleatom, atom/destination, precision=null, forceMove = TRUE, datum/effect_system/effectin=null, datum/effect_system/effectout=null, asoundin=null, asoundout=null, no_effects=FALSE, channel=TELEPORT_CHANNEL_BLUESPACE, forced = FALSE)
	// teleporting most effects just deletes them
	var/static/list/delete_atoms = typecacheof(list(
		/obj/effect,
		)) - typecacheof(list(
		/obj/effect/wisp,
		/obj/effect/mob_spawn,
		))
	if(delete_atoms[teleatom.type])
		qdel(teleatom)
		return FALSE

	// argument handling
	// if the precision is not specified, default to 0, but apply BoH penalties
	if (isnull(precision))
		precision = 0

	switch(channel)
		if(TELEPORT_CHANNEL_BLUESPACE)
			// if effects are not specified and not explicitly disabled, sparks
			if ((!effectin || !effectout) && !no_effects)
				var/datum/effect_system/spark_spread/sparks = new
				sparks.set_up(5, 1, teleatom)
				if (!effectin)
					effectin = sparks
				if (!effectout)
					effectout = sparks
		if(TELEPORT_CHANNEL_QUANTUM)
			// if effects are not specified and not explicitly disabled, rainbow sparks
			if ((!effectin || !effectout) && !no_effects)
				var/datum/effect_system/spark_spread/quantum/sparks = new
				sparks.set_up(5, 1, teleatom)
				if (!effectin)
					effectin = sparks
				if (!effectout)
					effectout = sparks

	// perform the teleport
	var/turf/curturf = get_turf(teleatom)
	var/turf/destturf = get_teleport_turf(get_turf(destination), precision)

	if(!destturf || !curturf || destturf.is_transition_turf())
		return FALSE

	var/area/A = get_area(curturf)
	var/area/B = get_area(destturf)
	if(!forced && (HAS_TRAIT(teleatom, TRAIT_NO_TELEPORT) || (A.area_flags & NO_TELEPORT) || (B.area_flags & NO_TELEPORT)))
		return FALSE

	if(SEND_SIGNAL(destturf, COMSIG_ATOM_INTERCEPT_TELEPORT, channel, curturf, destturf))
		return FALSE

	tele_play_specials(teleatom, curturf, effectin, asoundin)
	var/success = forceMove ? teleatom.forceMove(destturf) : teleatom.Move(destturf)
	if (success)
		log_game("[key_name(teleatom)] has teleported from [loc_name(curturf)] to [loc_name(destturf)]")
		tele_play_specials(teleatom, destturf, effectout, asoundout)

	if(ismob(teleatom))
		var/mob/M = teleatom
		M.cancel_camera()

	return TRUE

/proc/tele_play_specials(atom/movable/teleatom, atom/location, datum/effect_system/effect, sound)
	if (location && !isobserver(teleatom))
		if (sound)
			playsound(location, sound, 60, TRUE)
		if (effect)
			effect.attach(location)
			effect.start()

// Safe location finder
/proc/find_safe_turf(zlevel, list/zlevels, extended_safety_checks = FALSE)
	if(!zlevels)
		if (zlevel)
			zlevels = list(zlevel)
		else
			zlevels = SSmapping.levels_by_trait(ZTRAIT_STATION)
	var/cycles = 1000
	for(var/cycle in 1 to cycles)
		// DRUNK DIALLING WOOOOOOOOO
		var/x = rand(1, world.maxx)
		var/y = rand(1, world.maxy)
		var/z = pick(zlevels)
		var/random_location = locate(x,y,z)

		if(!isfloorturf(random_location))
			continue
		var/turf/open/floor/F = random_location

		if(extended_safety_checks)
			if(islava(F)) //chasms aren't /floor, and so are pre-filtered
				var/turf/open/lava/L = F
				if(!L.is_safe())
					continue

		// DING! You have passed the gauntlet, and are "probably" safe.
		return F

/proc/get_teleport_turfs(turf/center, precision = 0)
	if(!precision)
		return list(center)
	var/list/posturfs = list()
	for(var/turf/T in RANGE_TURFS(precision, center))
		if(T.is_transition_turf())
			continue // Avoid picking these.
		var/area/A = T.loc
		if(A.area_flags & NO_TELEPORT)
			continue
		posturfs.Add(T)
	return posturfs

/proc/get_teleport_turf(turf/center, precision = 0)
	return safepick(get_teleport_turfs(center, precision))
