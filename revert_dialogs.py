import os
import re

files_to_revert = [
    r"d:\DATN\badminton_ai\lib\widgets\time_filter_widget.dart",
    r"d:\DATN\badminton_ai\lib\utils\dialog_utils.dart",
    r"d:\DATN\badminton_ai\lib\screens\user\profile\profile_tab.dart",
    r"d:\DATN\badminton_ai\lib\screens\user\profile\components\statistics_filter_row.dart",
    r"d:\DATN\badminton_ai\lib\screens\user\home\home_tab.dart",
    r"d:\DATN\badminton_ai\lib\screens\user\chat\chatbot_tab.dart",
    r"d:\DATN\badminton_ai\lib\screens\user\booking\event_checkout_screen.dart",
    r"d:\DATN\badminton_ai\lib\screens\user\booking\court_selection_screen.dart",
    r"d:\DATN\badminton_ai\lib\screens\user\booking\components\booking_history\booking_card.dart",
    r"d:\DATN\badminton_ai\lib\screens\user\booking\checkout_screen.dart",
    r"d:\DATN\badminton_ai\lib\screens\admin\manage_users_screen.dart",
    r"d:\DATN\badminton_ai\lib\screens\admin\manage_courts_screen.dart"
]

def revert_cupertino(content):
    content = content.replace("showCustomCupertinoDialog", "showDialog")
    content = content.replace("showAlertCupertinoDialog", "showDialog")
    
    content = content.replace("showCupertinoDialog", "showDialog")
    content = content.replace("CupertinoAlertDialog", "AlertDialog")
    content = content.replace("CupertinoDialogAction", "TextButton")
    
    content = re.sub(r'isDefaultAction\s*:\s*(true|false)\s*,?', '', content)
    content = re.sub(r'isDestructiveAction\s*:\s*(true|false)\s*,?', '', content)
    
    content = content.replace("CupertinoActivityIndicator()", "CircularProgressIndicator()")
    content = content.replace("const CupertinoActivityIndicator()", "const CircularProgressIndicator()")
    
    return content

for path in files_to_revert:
    if not os.path.exists(path):
        print(f"Not found: {path}")
        continue
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    new_content = revert_cupertino(content)
    if new_content != content:
        with open(path, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"Reverted {path}")
