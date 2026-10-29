package com.gymia.app

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

/** Same cases as test/reminder_render_test.dart: both sides must write the same text. */
class ReminderTextTest {
    private fun templates(tone: String, companionId: String = "lectura"): JSONObject {
        val cheer = tone == "cheer"
        fun arr(vararg v: String) = JSONArray(v.toList())
        return JSONObject()
            .put("windowStart", if (cheer) arr("{nombre} te espera: hoy toca {meta}.", "{nombre} te espera hoy.")
                else arr("Es buen momento para tu actividad. Meta de hoy: {meta}.", "Es buen momento para tu actividad."))
            .put("lastCall", if (cheer) arr("Última llamada: con {minimo} mantienes tu racha de {racha} días.",
                "No pierdas la racha: te faltan {faltan} esta semana.", "Última llamada para hoy.")
                else arr("Aún estás a tiempo hoy. Con {minimo} basta.", "Te faltan {faltan} esta semana.", "Aún estás a tiempo hoy."))
            .put("inactive", JSONArray().apply {
                if (cheer && companionId == "gymbro") put("Amigo, llevamos {dias} días sin entrenar. Vamos a movernos un poco.")
                if (cheer) { put("Llevamos {dias} días sin vernos. ¿Algo corto hoy?"); put("¿Algo corto hoy?") }
                else { put("Llevas {dias} días sin registrar."); put("Hace unos días que no registras.") }
            })
    }

    private fun entry(
        tone: String = "neutral",
        companionId: String = "lectura",
        name: String = "Lectura",
        lastActivity: String? = "2026-10-28",
        streak: Int = 0,
        goal: String? = null,
        minimum: String? = null,
        weekId: String? = "2026-W44",
        weekCount: Int = 0,
        weekTarget: Int? = null,
    ) = JSONObject()
        .put("companionId", companionId).put("companionName", name)
        .put("lastActivityDate", lastActivity ?: JSONObject.NULL)
        .put("streak", streak)
        .put("goalText", goal ?: JSONObject.NULL)
        .put("minimumText", minimum ?: JSONObject.NULL)
        .put("weekId", weekId ?: JSONObject.NULL)
        .put("weekCount", weekCount)
        .put("weekTarget", weekTarget ?: JSONObject.NULL)
        .put("templates", templates(tone, companionId))

    // Thursday 2026-10-29, week 2026-W44.
    private fun start(e: JSONObject) = ReminderText.render(e, ReminderText.WINDOW_START, 2026, 10, 29)
    private fun last(e: JSONObject) = ReminderText.render(e, ReminderText.LAST_CALL, 2026, 10, 29)

    @Test fun startUsesTheGoalOnlyWhenThereIsOne() {
        assertEquals("Es buen momento para tu actividad. Meta de hoy: 20 páginas.", start(entry(goal = "20 páginas")))
        assertEquals("Es buen momento para tu actividad.", start(entry()))
        assertEquals("Lectura te espera: hoy toca 20 páginas.", start(entry(tone = "cheer", goal = "20 páginas")))
        assertEquals("Lectura te espera hoy.", start(entry(tone = "cheer")))
    }

    @Test fun inactiveOnlyWhenOlderThanYesterday() {
        assertEquals("Llevas 3 días sin registrar.", start(entry(lastActivity = "2026-10-26")))
        assertEquals("Llevas 2 días sin registrar.", start(entry(lastActivity = "2026-10-27")))
        assertTrue(start(entry(lastActivity = "2026-10-28")).contains("buen momento"))
        assertTrue(start(entry(lastActivity = "2026-10-29")).contains("buen momento"))
        assertTrue(start(entry(lastActivity = null)).contains("buen momento"))
        assertEquals("Llevamos 4 días sin vernos. ¿Algo corto hoy?", start(entry(tone = "cheer", lastActivity = "2026-10-25")))
    }

    @Test fun gymbroHasItsOwnCheerText() {
        val own = "Amigo, llevamos 4 días sin entrenar. Vamos a movernos un poco."
        assertEquals(own, start(entry(tone = "cheer", companionId = "gymbro", name = "GymBro", lastActivity = "2026-10-25")))
        assertEquals("Llevas 4 días sin registrar.", start(entry(companionId = "gymbro", name = "GymBro", lastActivity = "2026-10-25")))
        assertNotEquals(own, start(entry(tone = "cheer", lastActivity = "2026-10-25")))
    }

    @Test fun lastCallPrefersMinimumThenWeeklyGapThenPlain() {
        assertEquals("Aún estás a tiempo hoy. Con 5 páginas basta.", last(entry(minimum = "5 páginas", weekTarget = 5, weekCount = 3)))
        assertEquals("Te faltan 2 esta semana.", last(entry(weekTarget = 5, weekCount = 3)))
        assertEquals("Aún estás a tiempo hoy.", last(entry()))
        assertEquals("Última llamada: con 5 páginas mantienes tu racha de 6 días.", last(entry(tone = "cheer", minimum = "5 páginas", streak = 6)))
        assertEquals("No pierdas la racha: te faltan 4 esta semana.", last(entry(tone = "cheer", minimum = "5 páginas", weekTarget = 5, weekCount = 1)))
        assertEquals("Última llamada para hoy.", last(entry(tone = "cheer", minimum = "5 páginas")))
        assertEquals("Última llamada para hoy.", last(entry(tone = "cheer", minimum = "5 páginas", streak = 0)))
    }

    @Test fun weeklyGapEdgeCases() {
        assertEquals("Aún estás a tiempo hoy.", last(entry(weekTarget = 3, weekCount = 3)))
        assertEquals("Aún estás a tiempo hoy.", last(entry(weekTarget = 3, weekCount = 5)))
        assertEquals("Te faltan 4 esta semana.", last(entry(weekId = "2026-W43", weekTarget = 4, weekCount = 4)))
        assertEquals("Aún estás a tiempo hoy.", last(entry(lastActivity = "2026-10-20")))
    }

    @Test fun isoWeeksFollowTheStandard() {
        assertEquals("2026-W44", ReminderText.isoWeekId(2026, 10, 29))
        assertEquals("2020-W53", ReminderText.isoWeekId(2021, 1, 3))
        assertEquals("2025-W01", ReminderText.isoWeekId(2024, 12, 30))
        assertEquals("2026-W01", ReminderText.isoWeekId(2026, 1, 1))
    }

    @Test fun weekdaysStartOnMonday() {
        assertEquals(3, ReminderText.weekdayIndex(ReminderText.epochDay(2026, 10, 29))) // Thursday
        assertEquals(0, ReminderText.weekdayIndex(ReminderText.epochDay(2026, 11, 2)))
        assertEquals(6, ReminderText.weekdayIndex(ReminderText.epochDay(2026, 11, 8)))
        assertEquals(0L, ReminderText.epochDay(1970, 1, 1))
    }

    private fun at(year: Int, month: Int, day: Int, hour: Int, minute: Int, zone: TimeZone): Long =
        Calendar.getInstance(zone).apply { clear(); set(year, month - 1, day, hour, minute) }.timeInMillis

    @Test fun nextTriggerSkipsUnmarkedDaysAndPastTimes() {
        val zone = TimeZone.getTimeZone("Europe/Madrid")
        val now = at(2026, 10, 29, 20, 0, zone) // Thursday 20:00
        // Everyday at 21:00: later today.
        assertEquals(at(2026, 10, 29, 21, 0, zone), ReminderText.nextTrigger(127, 21 * 60, now, zone))
        // Everyday at 19:00: tomorrow.
        assertEquals(at(2026, 10, 30, 19, 0, zone), ReminderText.nextTrigger(127, 19 * 60, now, zone))
        // Only Mondays (bit 0): the next Monday is Nov 2.
        assertEquals(at(2026, 11, 2, 21, 0, zone), ReminderText.nextTrigger(1, 21 * 60, now, zone))
        // Exactly now is not "after now".
        assertEquals(at(2026, 10, 30, 20, 0, zone), ReminderText.nextTrigger(127, 20 * 60, now, zone))
        // Only Thursdays at 19:00: next week.
        assertEquals(at(2026, 11, 5, 19, 0, zone), ReminderText.nextTrigger(1 shl 3, 19 * 60, now, zone))
        assertNull(ReminderText.nextTrigger(0, 600, now, zone))
    }

    @Test fun nextTriggerUsesTheLocalZone() {
        val tokyo = TimeZone.getTimeZone("Asia/Tokyo")
        val madrid = TimeZone.getTimeZone("Europe/Madrid")
        val now = at(2026, 10, 29, 20, 0, madrid)
        val inTokyo = ReminderText.nextTrigger(127, 21 * 60, now, tokyo)!!
        val inMadrid = ReminderText.nextTrigger(127, 21 * 60, now, madrid)!!
        assertNotEquals(inTokyo, inMadrid)
    }
}
