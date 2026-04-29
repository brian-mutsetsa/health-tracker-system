import os

file_path = r'c:\dev\projects\health_tracker_system\backend\api\views.py'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

emojis = ['✅', '⚠️', '📥', '🤖', '❌', '🗑️', '🌱', '👨‍⚕️', '🗓️', '💬', '✓']
for e in emojis:
    content = content.replace(e, '')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Removed emojis")
