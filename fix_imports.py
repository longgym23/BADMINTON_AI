import os

files_to_fix = [
    r"d:\DATN\badminton_ai\lib\screens\admin\admin_dashboard_screen.dart",
    r"d:\DATN\badminton_ai\lib\screens\admin\manage_courts_screen.dart",
    r"d:\DATN\badminton_ai\lib\screens\admin\manage_users_screen.dart",
    r"d:\DATN\badminton_ai\lib\screens\user\booking\checkout_screen.dart",
    r"d:\DATN\badminton_ai\lib\screens\user\booking\components\booking_history\booking_card.dart",
    r"d:\DATN\badminton_ai\lib\screens\user\booking\components\booking_history\filter_section.dart",
    r"d:\DATN\badminton_ai\lib\screens\user\booking\court_selection_screen.dart",
    r"d:\DATN\badminton_ai\lib\screens\user\booking\event_checkout_screen.dart",
    r"d:\DATN\badminton_ai\lib\screens\user\chat\chatbot_tab.dart",
    r"d:\DATN\badminton_ai\lib\screens\user\home\home_tab.dart",
    r"d:\DATN\badminton_ai\lib\screens\user\profile\components\statistics_filter_row.dart",
    r"d:\DATN\badminton_ai\lib\screens\user\profile\profile_tab.dart",
    r"d:\DATN\badminton_ai\lib\widgets\time_filter_widget.dart"
]

import_cupertino = "import 'package:flutter/cupertino.dart';\n"
import_dialog = "import 'package:badminton_ai/utils/dialog_utils.dart';\n"

for fpath in files_to_fix:
    if not os.path.exists(fpath):
        continue
    with open(fpath, "r", encoding="utf-8") as f:
        content = f.read()

    lines = content.splitlines(True)
    
    modified = False
    if "package:flutter/cupertino.dart" not in content:
        # Find the last import
        for i, line in reversed(list(enumerate(lines))):
            if line.startswith("import "):
                lines.insert(i+1, import_cupertino)
                modified = True
                break
        else:
            lines.insert(0, import_cupertino)
            modified = True
            
    if "manage_courts_screen" in fpath and "package:badminton_ai/utils/dialog_utils.dart" not in content:
        for i, line in reversed(list(enumerate(lines))):
            if line.startswith("import "):
                lines.insert(i+1, import_dialog)
                modified = True
                break
        else:
            lines.insert(0, import_cupertino)
            
    if modified:
        with open(fpath, "w", encoding="utf-8") as f:
            f.writelines(lines)
        print("Fixed", fpath)
