# EdgeTX_All_Switches_Widget

A dynamic, visual switch-state tracker for EdgeTX radios (like the TX16S). 

This widget displays the status of your switches using custom labels pulled from model-specific files, featuring a high-contrast "Layered Border" design for maximum readability.

📂 Folder Structure
To function correctly, the files must be placed on your SD card exactly as follows:
SD Card/WIDGETS/All_Switches/main.lua
SD Card/WIDGETS/All_Switches/radio/TX16S.lua
SD Card/WIDGETS/All_Switches/labels/global.lua
SD Card/WIDGETS/All_Switches/labels/[MODEL_NAME].lua

🛠️ Label Configuration
The core of this widget is the labeling system. It looks for text in two places:
Global Labels: Used for switches that do the same thing on every model (e.g., Arming or Turtle Mode).
Model Labels: Used for specific model functions.

⚠️ Critical: Model Naming
The filename for your model labels must match the Model Name in your radio exactly, including spaces and capitalization. 
If your model is named Mobula7, the file must be labels/Mobula7.lua. If your model is named Granite 4x4, the file must be labels/Granite 4x4.lua.

🔡 Understanding the u, m, and d Logic
When creating labels in your .lua files, you define the text for the three physical positions of a switch.  
u - "up" - Switch pushed away from you.
m - "Middle" - switch in the center position
d - "Down" - Switch pulled toward you
Example entry in labels/global.lua:

return {
  ["SAu"] = "DISARMED",
  ["SAd"] = "ARMED",
  ["SBm"] = "STAB",
  ["SBd"] = "ACRO",


🎨 Visual Features
Layered Borders: Uses a 1-pixel white border around rounded corners, specifically designed to bypass EdgeTX anti-aliasing issues. 
Auto-Hide: In the widget settings, you can toggle "Auto-Hide." When ON, the widget will only draw boxes for switches that actually have labels assigned to them.
Active Highlighting: The label corresponding to the current physical switch position will change color (default to White or Theme Focus) to show it is active.

🚀 How to Install
Copy the All_Switches folder to your SD card's WIDGETS directory. On your radio, long-press TELEMETRY to enter the setup screen. Select a full app screen widget layout (this is a full screen widget), click Setup Widget, and choose All_Switches.  Configure your colors and "Auto-Hide" preference in the options menu.
