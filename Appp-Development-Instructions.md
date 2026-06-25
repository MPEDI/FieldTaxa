# How to develop using a Design Handoff



***Download FieldTaxa Flutter Handoff Package***



The zip contains two files:

- **README.md** — complete Flutter implementation spec: all color tokens (light + dark), typography, every screen layout, data model (Dart classes), navigation routes, state management structure, recommended packages, localisation keys, and notes for Claude Code
- **FieldTaxa Reference.html** — the fully interactive prototype to open alongside the README while building

**To hand off to Claude Code:** Open a terminal in your Flutter project folder, start a Claude Code session, and tell it:

> *"I have a design handoff package in `design_handoff_fieldtaxa/`. Read the README.md first, then open the HTML reference in a browser. Implement the FieldTaxa Flutter app following the spec exactly."*

Claude Code will read the README, use the prototype as a visual reference, and scaffold the full Flutter app.

