import sqlite3
import json

conn = sqlite3.connect('tasks.db')
cursor = conn.cursor()
cursor.execute('SELECT * FROM tasks')
rows = cursor.fetchall()
conn.close()

with open('db_dump_utf8.md', 'w', encoding='utf-8') as f:
    f.write('| ID | Title | Description | Due Date | Status | Blocked By |\n')
    f.write('|---|---|---|---|---|---|\n')
    for r in rows:
        f.write(f'| {r[0]} | {r[1]} | {r[2]} | {r[3]} | {r[4]} | {r[5]} |\n')
