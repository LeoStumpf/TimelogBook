#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Writes a database with demo entries for the store screenshots.

usage: tool/demo_db.py <output.db>
Today is 5 Nov 2026 with an entry running since 12:41. Set the device clock to
that afternoon, in the time zone below, before taking screenshots.
"""
import sqlite3
import sys
from datetime import datetime
from zoneinfo import ZoneInfo

ZONE = ZoneInfo('Europe/Berlin')
DAYS = {
    '2026-10-29': ['07:40-11:40', '12:15-15:00', '15:20-16:46'],
    '2026-10-30': ['07:30-13:00'],
    '2026-11-02': ['08:02-12:10', '12:45-16:15'],
    '2026-11-03': ['07:45-12:00', '12:30-16:19'],
    '2026-11-04': ['07:31-11:30', '12:10-14:20', '14:40-16:23'],
    '2026-11-05': ['07:48-12:02', '12:41-'],
}


def ms(day, time):
    if not time:
        return None
    return int(datetime.fromisoformat(f'{day}T{time}').replace(tzinfo=ZONE).timestamp() * 1000)


db = sqlite3.connect(sys.argv[1])
db.execute('''CREATE TABLE sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    start_ms INTEGER NOT NULL,
    end_ms INTEGER,
    day TEXT NOT NULL)''')
db.execute('CREATE INDEX idx_sessions_day ON sessions(day)')
for day, entries in DAYS.items():
    for entry in entries:
        start, end = entry.split('-')
        db.execute(
            'INSERT INTO sessions (start_ms, end_ms, day) VALUES (?, ?, ?)',
            (ms(day, start), ms(day, end), day),
        )
db.execute('PRAGMA user_version = 1')
db.commit()
