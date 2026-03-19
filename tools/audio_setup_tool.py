#!/usr/bin/env python3
"""
Audio Setup Tool - Standalone WAV-to-entity mapping tool for Hold The Line.
Maps .wav files to entity sound cues and saves to data/sfx_assignments.json.

Usage: python tools/audio_setup_tool.py
Run from the project root (C:\Godot\hold_the_line) or it will auto-detect.
"""

import json
import os
import sys
import tkinter as tk
from tkinter import ttk
from pathlib import Path

# ── Paths ──────────────────────────────────────────────────────────

def find_project_root():
    """Find the project root by looking for project.godot."""
    # Try script directory's parent
    script_dir = Path(__file__).resolve().parent
    for candidate in [script_dir.parent, Path.cwd(), Path.cwd().parent]:
        if (candidate / "project.godot").exists():
            return candidate
    print("ERROR: Could not find project.godot. Run from the project root.")
    sys.exit(1)

PROJECT_ROOT = find_project_root()
DATA_DIR = PROJECT_ROOT / "data"
SFX_DIR = PROJECT_ROOT / "audio" / "sfx"
SAVE_PATH = DATA_DIR / "sfx_assignments.json"

# ── Entity / Cue Definitions ──────────────────────────────────────

CENTRAL_TOWER_CUES = [
    ("upgrade", "Upgrade"),
    ("hp_50", "HP Reaches 50%"),
    ("hp_10", "HP Reaches 10%"),
    ("death", "Death"),
]
TOWER_CUES = [
    ("placement", "Placement"),
    ("upgrade", "Upgrade"),
    ("attack", "Attack / Main Ability"),
    ("death", "Death"),
    ("sell", "Sell"),
]
UNIT_CUES = [
    ("spawn", "Spawn"),
    ("order_received", "Order Received"),
    ("attack", "Attack"),
    ("ability_1", "Ability 1"),
    ("ability_2", "Ability 2"),
    ("ability_3", "Ability 3"),
    ("death", "Death"),
]
ENEMY_CUES = [
    ("attack", "Attack"),
    ("roar", "Roar"),
    ("death", "Death"),
]
PRODUCTION_CUES = [
    ("placement", "Placement"),
    ("death", "Death"),
    ("sell", "Sell"),
]
BARRIER_CUES = [
    ("death", "Death"),
]

TYPE_TO_CUES = {
    "central_tower": CENTRAL_TOWER_CUES,
    "tower": TOWER_CUES,
    "unit": UNIT_CUES,
    "enemy": ENEMY_CUES,
    "production": PRODUCTION_CUES,
    "barrier": BARRIER_CUES,
}

# ── Data Loading ──────────────────────────────────────────────────

def load_json_ids(filename, array_key):
    """Load entity IDs from a JSON data file."""
    path = DATA_DIR / filename
    if not path.exists():
        return []
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    return [entry["id"] for entry in data.get(array_key, []) if "id" in entry]


def load_central_tower_id():
    path = DATA_DIR / "central_tower.json"
    if not path.exists():
        return []
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    return [data.get("id", "central_tower")]


def gather_categories():
    """Build the category list with entity IDs and types."""
    categories = []

    ct_ids = load_central_tower_id()
    if ct_ids:
        categories.append(("CENTRAL TOWER", [(eid, "central_tower") for eid in ct_ids]))

    off = load_json_ids("towers_offensive.json", "towers")
    if off:
        categories.append(("TOWERS - Offensive", [(eid, "tower") for eid in off]))

    res = load_json_ids("towers_resource.json", "towers")
    if res:
        categories.append(("TOWERS - Resource", [(eid, "tower") for eid in res]))

    sup = load_json_ids("towers_support.json", "towers")
    if sup:
        categories.append(("TOWERS - Support", [(eid, "tower") for eid in sup]))

    drones = load_json_ids("units_drone.json", "units")
    if drones:
        categories.append(("UNITS - Drone", [(eid, "unit") for eid in drones]))

    mechs = load_json_ids("units_mech.json", "units")
    if mechs:
        categories.append(("UNITS - Mech", [(eid, "unit") for eid in mechs]))

    vehicles = load_json_ids("units_war.json", "units")
    if vehicles:
        categories.append(("UNITS - Vehicle", [(eid, "unit") for eid in vehicles]))

    enemies = load_json_ids("enemies.json", "enemies")
    if enemies:
        categories.append(("ENEMIES", [(eid, "enemy") for eid in enemies]))

    prod = load_json_ids("production_buildings.json", "buildings")
    if prod:
        categories.append(("PRODUCTION BUILDINGS", [(eid, "production") for eid in prod]))

    barriers = load_json_ids("barriers.json", "barriers")
    if barriers:
        categories.append(("BARRIERS", [(eid, "barrier") for eid in barriers]))

    return categories


def scan_wav_files():
    """Recursively scan the SFX directory for .wav files."""
    wavs = []
    if not SFX_DIR.exists():
        return wavs
    for root, _dirs, files in os.walk(SFX_DIR):
        for f in files:
            if f.lower().endswith(".wav"):
                full = Path(root) / f
                # Convert to Godot res:// path
                rel = full.relative_to(PROJECT_ROOT)
                godot_path = "res://" + str(rel).replace("\\", "/")
                wavs.append(godot_path)
    wavs.sort()
    return wavs


def make_default_cue(cue_id):
    d = {"files": ["", "", ""], "pitch_randomize": False, "pitch_cents": 50}
    if cue_id == "roar":
        d["roar_chance"] = 10
        d["roar_interval"] = 10.0
    return d


def load_sfx_data(categories):
    """Load existing sfx_assignments.json, filling defaults for missing entries."""
    data = {}
    if SAVE_PATH.exists():
        with open(SAVE_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)

    # Ensure all entities and cues have entries
    for _cat_name, entities in categories:
        for eid, etype in entities:
            if eid not in data:
                data[eid] = {}
            for cue_id, _label in TYPE_TO_CUES.get(etype, []):
                if cue_id not in data[eid]:
                    data[eid][cue_id] = make_default_cue(cue_id)
                else:
                    # Ensure files array has 3 slots
                    files = data[eid][cue_id].get("files", [])
                    while len(files) < 3:
                        files.append("")
                    data[eid][cue_id]["files"] = files
    return data


def save_sfx_data(data):
    with open(SAVE_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, indent="\t")


# ── Colors ─────────────────────────────────────────────────────────

BG = "#14171e"
BG_DARK = "#0e1016"
ACCENT = "#4de680"
ACCENT_DIM = "#2a5e38"
SUBHEADER = "#80b38a"
TEXT = "#ccd9cc"
DIM = "#737373"
SELECTED_BG = "#1f3d28"
CUE_BG = "#12141c"
BORDER = "#264d36"
SLOT_BG = "#0d0f14"
HOVER_BG = "#1e2e24"

# ── Application ────────────────────────────────────────────────────

class AudioSetupApp:
    def __init__(self):
        self.categories = gather_categories()
        self.wav_files = scan_wav_files()
        self.sfx_data = load_sfx_data(self.categories)
        self.entity_types = {}
        for _cat, entities in self.categories:
            for eid, etype in entities:
                self.entity_types[eid] = etype

        self.selected_entity = None
        self.entity_buttons = {}

        self.root = tk.Tk()
        self.root.title("Audio Setup Tool - Hold The Line")
        self.root.geometry("1200x800")
        self.root.configure(bg=BG)
        self.root.minsize(900, 600)

        self._build_ui()
        self._populate_entity_list()

        # Select first entity
        if self.categories:
            first_eid = self.categories[0][1][0][0]
            self._select_entity(first_eid)

    def run(self):
        self.root.mainloop()

    # ── UI Building ────────────────────────────────────────────────

    def _build_ui(self):
        # Title bar
        title_frame = tk.Frame(self.root, bg=BG)
        title_frame.pack(fill="x", padx=12, pady=(10, 4))

        tk.Label(title_frame, text="AUDIO SETUP TOOL", font=("Segoe UI", 18, "bold"),
                 fg=ACCENT, bg=BG).pack(side="left")

        self.status_label = tk.Label(title_frame,
                                     text=f"{len(self.wav_files)} WAV files available",
                                     font=("Segoe UI", 10), fg=DIM, bg=BG)
        self.status_label.pack(side="right")

        # Main paned window
        paned = tk.PanedWindow(self.root, orient="horizontal", bg=BG,
                                sashwidth=4, sashrelief="flat")
        paned.pack(fill="both", expand=True, padx=8, pady=(4, 8))

        # Left panel - entity list
        left_frame = tk.Frame(paned, bg=BG_DARK, width=260)
        paned.add(left_frame, minsize=200, width=260)

        # Filter
        filter_frame = tk.Frame(left_frame, bg=BG_DARK)
        filter_frame.pack(fill="x", padx=6, pady=6)

        self.filter_var = tk.StringVar()
        self.filter_var.trace_add("write", lambda *_: self._on_filter_changed())
        filter_entry = tk.Entry(filter_frame, textvariable=self.filter_var,
                                font=("Segoe UI", 11), bg=SLOT_BG, fg=TEXT,
                                insertbackground=TEXT, relief="flat",
                                highlightthickness=1, highlightcolor=ACCENT_DIM,
                                highlightbackground=BORDER)
        filter_entry.pack(fill="x")
        filter_entry.insert(0, "")
        # Placeholder
        self._setup_placeholder(filter_entry, "Filter entities...")

        # Scrollable entity list
        list_canvas = tk.Canvas(left_frame, bg=BG_DARK, highlightthickness=0)
        list_scrollbar = tk.Scrollbar(left_frame, orient="vertical",
                                       command=list_canvas.yview)
        self.entity_list_frame = tk.Frame(list_canvas, bg=BG_DARK)

        self.entity_list_frame.bind("<Configure>",
            lambda e: list_canvas.configure(scrollregion=list_canvas.bbox("all")))
        list_canvas.create_window((0, 0), window=self.entity_list_frame, anchor="nw")
        list_canvas.configure(yscrollcommand=list_scrollbar.set)

        list_scrollbar.pack(side="right", fill="y")
        list_canvas.pack(side="left", fill="both", expand=True, padx=(6, 0))

        # Mousewheel scrolling
        def _on_mousewheel(event):
            list_canvas.yview_scroll(int(-1 * (event.delta / 120)), "units")
        list_canvas.bind("<MouseWheel>", _on_mousewheel)
        self.entity_list_frame.bind("<MouseWheel>", _on_mousewheel)
        self._list_canvas = list_canvas

        # Right panel - cue editor
        right_frame = tk.Frame(paned, bg=BG)
        paned.add(right_frame, minsize=500)

        self.entity_title = tk.Label(right_frame, text="Select an entity",
                                      font=("Segoe UI", 16, "bold"),
                                      fg=ACCENT, bg=BG, anchor="w")
        self.entity_title.pack(fill="x", padx=10, pady=(8, 2))

        sep = tk.Frame(right_frame, bg=BORDER, height=1)
        sep.pack(fill="x", padx=10, pady=(0, 6))

        # Scrollable cue area
        cue_canvas = tk.Canvas(right_frame, bg=BG, highlightthickness=0)
        cue_scrollbar = tk.Scrollbar(right_frame, orient="vertical",
                                      command=cue_canvas.yview)
        self.cue_frame = tk.Frame(cue_canvas, bg=BG)

        self.cue_frame.bind("<Configure>",
            lambda e: cue_canvas.configure(scrollregion=cue_canvas.bbox("all")))
        self._cue_canvas_window = cue_canvas.create_window((0, 0), window=self.cue_frame, anchor="nw")
        cue_canvas.configure(yscrollcommand=cue_scrollbar.set)

        # Make cue_frame fill canvas width
        def _on_cue_canvas_configure(event):
            cue_canvas.itemconfig(self._cue_canvas_window, width=event.width)
        cue_canvas.bind("<Configure>", _on_cue_canvas_configure)

        cue_scrollbar.pack(side="right", fill="y")
        cue_canvas.pack(side="left", fill="both", expand=True, padx=(6, 0))

        def _on_cue_mousewheel(event):
            cue_canvas.yview_scroll(int(-1 * (event.delta / 120)), "units")
        cue_canvas.bind("<MouseWheel>", _on_cue_mousewheel)
        self.cue_frame.bind("<MouseWheel>", _on_cue_mousewheel)
        self._cue_canvas = cue_canvas

    def _setup_placeholder(self, entry, placeholder):
        entry.insert(0, placeholder)
        entry.config(fg=DIM)

        def on_focus_in(e):
            if entry.get() == placeholder:
                entry.delete(0, "end")
                entry.config(fg=TEXT)

        def on_focus_out(e):
            if not entry.get():
                entry.insert(0, placeholder)
                entry.config(fg=DIM)

        entry.bind("<FocusIn>", on_focus_in)
        entry.bind("<FocusOut>", on_focus_out)

    # ── Entity List ────────────────────────────────────────────────

    def _populate_entity_list(self):
        for widget in self.entity_list_frame.winfo_children():
            widget.destroy()
        self.entity_buttons.clear()
        self._category_widgets = []

        for cat_name, entities in self.categories:
            header = tk.Label(self.entity_list_frame, text=cat_name,
                              font=("Segoe UI", 10, "bold"), fg=SUBHEADER, bg=BG_DARK,
                              anchor="w", pady=4)
            header.pack(fill="x", padx=4)

            entity_labels = []
            for eid, _etype in entities:
                display = eid.replace("_", " ").title()
                btn = tk.Label(self.entity_list_frame, text=f"  {display}",
                               font=("Segoe UI", 10), fg=TEXT, bg=BG_DARK,
                               anchor="w", pady=2, padx=4, cursor="hand2")
                btn.pack(fill="x")
                btn.bind("<Button-1>", lambda e, _eid=eid: self._select_entity(_eid))
                btn.bind("<Enter>", lambda e, b=btn: b.configure(bg=HOVER_BG)
                         if b != self.entity_buttons.get(self.selected_entity) else None)
                btn.bind("<Leave>", lambda e, b=btn: b.configure(bg=BG_DARK)
                         if b != self.entity_buttons.get(self.selected_entity) else None)
                btn.bind("<MouseWheel>", lambda e: self._list_canvas.yview_scroll(
                    int(-1 * (e.delta / 120)), "units"))
                self.entity_buttons[eid] = btn
                entity_labels.append(btn)

            self._category_widgets.append((header, entity_labels))

            spacer = tk.Frame(self.entity_list_frame, bg=BG_DARK, height=6)
            spacer.pack(fill="x")

    def _select_entity(self, entity_id):
        # Unhighlight previous
        if self.selected_entity and self.selected_entity in self.entity_buttons:
            self.entity_buttons[self.selected_entity].configure(bg=BG_DARK)

        self.selected_entity = entity_id

        # Highlight new
        if entity_id in self.entity_buttons:
            self.entity_buttons[entity_id].configure(bg=SELECTED_BG)

        etype = self.entity_types.get(entity_id, "unknown")
        display = entity_id.replace("_", " ").title()
        self.entity_title.configure(text=f"{display}  ({etype.replace('_', ' ').title()})")

        self._build_cue_editor(entity_id)

    def _on_filter_changed(self):
        filt = self.filter_var.get().lower()
        if filt == "filter entities...":
            filt = ""

        for header, entity_labels in self._category_widgets:
            any_visible = False
            for btn in entity_labels:
                if not filt or filt in btn.cget("text").lower():
                    btn.pack(fill="x")
                    any_visible = True
                else:
                    btn.pack_forget()
            if any_visible:
                header.pack(fill="x", padx=4)
            else:
                header.pack_forget()

    # ── Cue Editor ─────────────────────────────────────────────────

    def _build_cue_editor(self, entity_id):
        for widget in self.cue_frame.winfo_children():
            widget.destroy()

        etype = self.entity_types.get(entity_id, "")
        cues = TYPE_TO_CUES.get(etype, [])

        if entity_id not in self.sfx_data:
            self.sfx_data[entity_id] = {}

        for cue_id, cue_label in cues:
            if cue_id not in self.sfx_data[entity_id]:
                self.sfx_data[entity_id][cue_id] = make_default_cue(cue_id)
            self._create_cue_section(entity_id, cue_id, cue_label)

    def _create_cue_section(self, entity_id, cue_id, label):
        cue_data = self.sfx_data[entity_id][cue_id]

        # Cue panel
        panel = tk.Frame(self.cue_frame, bg=CUE_BG, highlightbackground=BORDER,
                         highlightthickness=1, padx=10, pady=8)
        panel.pack(fill="x", padx=8, pady=4)
        panel.bind("<MouseWheel>", lambda e: self._cue_canvas.yview_scroll(
            int(-1 * (e.delta / 120)), "units"))

        # Cue name
        tk.Label(panel, text=label, font=("Segoe UI", 13, "bold"),
                 fg=ACCENT, bg=CUE_BG).pack(anchor="w")

        # 3 WAV slots
        files = cue_data.get("files", ["", "", ""])
        while len(files) < 3:
            files.append("")

        for i in range(3):
            self._create_wav_slot(panel, entity_id, cue_id, i, files[i])

        # Pitch controls
        self._create_pitch_controls(panel, entity_id, cue_id, cue_data)

        # Roar controls
        if cue_id == "roar":
            self._create_roar_controls(panel, entity_id, cue_id, cue_data)

    def _create_wav_slot(self, parent, entity_id, cue_id, slot_index, current_file):
        row = tk.Frame(parent, bg=CUE_BG)
        row.pack(fill="x", pady=2)
        row.bind("<MouseWheel>", lambda e: self._cue_canvas.yview_scroll(
            int(-1 * (e.delta / 120)), "units"))

        tk.Label(row, text=f"[{slot_index + 1}]", font=("Segoe UI", 10),
                 fg=DIM, bg=CUE_BG, width=3).pack(side="left")

        display = os.path.basename(current_file) if current_file else "-- None --"
        color = TEXT if current_file else DIM

        file_btn = tk.Label(row, text=display, font=("Segoe UI", 10),
                            fg=color, bg=SLOT_BG, anchor="w", padx=6, pady=3,
                            cursor="hand2", relief="flat",
                            highlightbackground=BORDER, highlightthickness=1)
        file_btn.pack(side="left", fill="x", expand=True, padx=(4, 4))
        file_btn.bind("<Button-1>", lambda e: self._open_wav_picker(
            entity_id, cue_id, slot_index, file_btn))

        clear_btn = tk.Label(row, text=" x ", font=("Segoe UI", 9),
                             fg=DIM, bg=SLOT_BG, cursor="hand2", padx=4, pady=3,
                             highlightbackground=BORDER, highlightthickness=1)
        clear_btn.pack(side="left")
        clear_btn.bind("<Button-1>", lambda e: self._clear_slot(
            entity_id, cue_id, slot_index, file_btn))

    def _create_pitch_controls(self, parent, entity_id, cue_id, cue_data):
        row = tk.Frame(parent, bg=CUE_BG)
        row.pack(fill="x", pady=(6, 0))

        pitch_var = tk.BooleanVar(value=cue_data.get("pitch_randomize", False))
        cb = tk.Checkbutton(row, text="Pitch Randomize", variable=pitch_var,
                            font=("Segoe UI", 10), fg=TEXT, bg=CUE_BG,
                            selectcolor=BG_DARK, activebackground=CUE_BG,
                            activeforeground=TEXT,
                            command=lambda: self._set_pitch_randomize(
                                entity_id, cue_id, pitch_var.get()))
        cb.pack(side="left")

        tk.Label(row, text="  \u00b1", font=("Segoe UI", 11),
                 fg=TEXT, bg=CUE_BG).pack(side="left")

        cents_var = tk.IntVar(value=int(cue_data.get("pitch_cents", 50)))
        spin = tk.Spinbox(row, from_=5, to=200, increment=5, textvariable=cents_var,
                          width=5, font=("Segoe UI", 10), bg=SLOT_BG, fg=TEXT,
                          buttonbackground=BG_DARK, relief="flat",
                          highlightbackground=BORDER, highlightthickness=1,
                          command=lambda: self._set_pitch_cents(
                              entity_id, cue_id, cents_var.get()))
        spin.pack(side="left", padx=4)

        tk.Label(row, text="cents", font=("Segoe UI", 10),
                 fg=DIM, bg=CUE_BG).pack(side="left")

    def _create_roar_controls(self, parent, entity_id, cue_id, cue_data):
        row = tk.Frame(parent, bg=CUE_BG)
        row.pack(fill="x", pady=(4, 0))

        tk.Label(row, text="Chance: 1 in", font=("Segoe UI", 10),
                 fg=TEXT, bg=CUE_BG).pack(side="left")

        chance_var = tk.IntVar(value=int(cue_data.get("roar_chance", 10)))
        chance_spin = tk.Spinbox(row, from_=1, to=100, increment=1,
                                  textvariable=chance_var, width=4,
                                  font=("Segoe UI", 10), bg=SLOT_BG, fg=TEXT,
                                  buttonbackground=BG_DARK, relief="flat",
                                  highlightbackground=BORDER, highlightthickness=1,
                                  command=lambda: self._set_roar_chance(
                                      entity_id, cue_id, chance_var.get()))
        chance_spin.pack(side="left", padx=4)

        tk.Label(row, text="every", font=("Segoe UI", 10),
                 fg=TEXT, bg=CUE_BG).pack(side="left", padx=(8, 0))

        interval_var = tk.DoubleVar(value=float(cue_data.get("roar_interval", 10.0)))
        interval_spin = tk.Spinbox(row, from_=1.0, to=60.0, increment=1.0,
                                    textvariable=interval_var, width=5,
                                    font=("Segoe UI", 10), bg=SLOT_BG, fg=TEXT,
                                    buttonbackground=BG_DARK, relief="flat",
                                    highlightbackground=BORDER, highlightthickness=1,
                                    command=lambda: self._set_roar_interval(
                                        entity_id, cue_id, interval_var.get()))
        interval_spin.pack(side="left", padx=4)

        tk.Label(row, text="s", font=("Segoe UI", 10),
                 fg=DIM, bg=CUE_BG).pack(side="left")

    # ── WAV Picker ─────────────────────────────────────────────────

    def _open_wav_picker(self, entity_id, cue_id, slot_index, file_label):
        picker = tk.Toplevel(self.root)
        picker.title("Select WAV File")
        picker.geometry("500x500")
        picker.configure(bg=BG_DARK)
        picker.transient(self.root)
        picker.grab_set()

        # Center on parent
        picker.update_idletasks()
        x = self.root.winfo_x() + (self.root.winfo_width() - 500) // 2
        y = self.root.winfo_y() + (self.root.winfo_height() - 500) // 2
        picker.geometry(f"+{x}+{y}")

        tk.Label(picker, text="Select WAV File", font=("Segoe UI", 14, "bold"),
                 fg=ACCENT, bg=BG_DARK).pack(padx=10, pady=(10, 4))

        # Search
        search_var = tk.StringVar()
        search_entry = tk.Entry(picker, textvariable=search_var,
                                font=("Segoe UI", 11), bg=SLOT_BG, fg=TEXT,
                                insertbackground=TEXT, relief="flat",
                                highlightthickness=1, highlightcolor=ACCENT_DIM,
                                highlightbackground=BORDER)
        search_entry.pack(fill="x", padx=10, pady=4)
        search_entry.focus_set()

        # Listbox
        list_frame = tk.Frame(picker, bg=BG_DARK)
        list_frame.pack(fill="both", expand=True, padx=10, pady=4)

        scrollbar = tk.Scrollbar(list_frame)
        scrollbar.pack(side="right", fill="y")

        listbox = tk.Listbox(list_frame, font=("Segoe UI", 10), bg=SLOT_BG, fg=TEXT,
                             selectbackground=ACCENT_DIM, selectforeground=TEXT,
                             relief="flat", highlightthickness=0,
                             yscrollcommand=scrollbar.set)
        listbox.pack(fill="both", expand=True)
        scrollbar.config(command=listbox.yview)

        # Track full paths alongside display names
        wav_paths = []

        def populate(filter_text=""):
            listbox.delete(0, "end")
            wav_paths.clear()
            ft = filter_text.lower()
            sfx_prefix = "res://audio/sfx/"
            for wav in self.wav_files:
                display = wav.replace(sfx_prefix, "") if wav.startswith(sfx_prefix) else wav
                if not ft or ft in display.lower():
                    listbox.insert("end", display)
                    wav_paths.append(wav)

        populate()

        search_var.trace_add("write", lambda *_: populate(search_var.get()))

        def on_select():
            sel = listbox.curselection()
            if not sel:
                return
            chosen_path = wav_paths[sel[0]]
            self.sfx_data[entity_id][cue_id]["files"][slot_index] = chosen_path
            file_label.configure(text=os.path.basename(chosen_path), fg=TEXT)
            save_sfx_data(self.sfx_data)
            self._flash_status("Saved")
            picker.destroy()

        def on_clear():
            self.sfx_data[entity_id][cue_id]["files"][slot_index] = ""
            file_label.configure(text="-- None --", fg=DIM)
            save_sfx_data(self.sfx_data)
            self._flash_status("Saved")
            picker.destroy()

        # Double click to select
        listbox.bind("<Double-Button-1>", lambda e: on_select())

        # Buttons
        btn_frame = tk.Frame(picker, bg=BG_DARK)
        btn_frame.pack(fill="x", padx=10, pady=(4, 10))

        for text, cmd in [("Select", on_select), ("Clear (None)", on_clear),
                          ("Cancel", picker.destroy)]:
            b = tk.Button(btn_frame, text=text, font=("Segoe UI", 10),
                          bg=BG, fg=TEXT, activebackground=HOVER_BG,
                          activeforeground=TEXT, relief="flat", padx=12, pady=4,
                          cursor="hand2", command=cmd)
            b.pack(side="right", padx=4)

        # Enter key to select
        picker.bind("<Return>", lambda e: on_select())
        picker.bind("<Escape>", lambda e: picker.destroy())

    # ── Data Mutations ─────────────────────────────────────────────

    def _clear_slot(self, entity_id, cue_id, slot_index, file_label):
        self.sfx_data[entity_id][cue_id]["files"][slot_index] = ""
        file_label.configure(text="-- None --", fg=DIM)
        save_sfx_data(self.sfx_data)
        self._flash_status("Saved")

    def _set_pitch_randomize(self, entity_id, cue_id, value):
        self.sfx_data[entity_id][cue_id]["pitch_randomize"] = value
        save_sfx_data(self.sfx_data)
        self._flash_status("Saved")

    def _set_pitch_cents(self, entity_id, cue_id, value):
        self.sfx_data[entity_id][cue_id]["pitch_cents"] = int(value)
        save_sfx_data(self.sfx_data)
        self._flash_status("Saved")

    def _set_roar_chance(self, entity_id, cue_id, value):
        self.sfx_data[entity_id][cue_id]["roar_chance"] = int(value)
        save_sfx_data(self.sfx_data)
        self._flash_status("Saved")

    def _set_roar_interval(self, entity_id, cue_id, value):
        self.sfx_data[entity_id][cue_id]["roar_interval"] = float(value)
        save_sfx_data(self.sfx_data)
        self._flash_status("Saved")

    def _flash_status(self, text):
        self.status_label.configure(text=text, fg=ACCENT)
        self.root.after(2000, lambda: self.status_label.configure(
            text=f"{len(self.wav_files)} WAV files available", fg=DIM))


# ── Main ───────────────────────────────────────────────────────────

if __name__ == "__main__":
    app = AudioSetupApp()
    app.run()
