import functools
import os
import re
from typing import List

from libqtile import bar, hook, qtile
from libqtile.backend.x11.window import Window
from libqtile.config import Screen, Group, Match, Key, Drag
from libqtile.core.manager import Qtile
from libqtile.layout.floating import Floating
from libqtile.layout.xmonad import MonadTall
from libqtile.lazy import lazy

from libqtile.widget.caps_num_lock_indicator import CapsNumLockIndicator
from libqtile.widget.chord import Chord
from libqtile.widget.clock import Clock
from libqtile.widget.cpu import CPU
from libqtile.widget.groupbox import GroupBox
from libqtile.widget.keyboardlayout import KeyboardLayout
from libqtile.widget.memory import Memory
from libqtile.widget.net import Net
from libqtile.widget.nvidia_sensors import NvidiaSensors
from libqtile.widget.sensors import ThermalSensor
from libqtile.widget.spacer import Spacer
from libqtile.widget.systray import Systray
from libqtile.widget.tasklist import TaskList
from libqtile.widget.textbox import TextBox
from libqtile.widget.battery import Battery
from libqtile.widget.backlight import Backlight

super_mod = "mod4"
control = "control"
shift = "shift"
alt = "mod1"
enter = "Return"
escape = "Escape"
tab = "Tab"
print_screen = "Print"

main = None

follow_mouse_focus = False
bring_front_click = False
cursor_warp = False

auto_fullscreen = True

focus_on_window_activation = "focus"

wmname = "qtile"


def make_goto_group(new_group_name: str):

  @lazy.function
  def goto_group(_qtile: Qtile):
    if new_group_name == _qtile.current_group.name:
      return

    _qtile.current_screen.set_group(_qtile.groups_map[new_group_name])

  return goto_group


def make_goto_group_with_current_window(new_group_name: str):

  @lazy.function
  def goto_group_with_current_window(_qtile: Qtile):
    if new_group_name == _qtile.current_group.name:
      return

    if _qtile.current_window is None:
      return

    _qtile.current_window.togroup(new_group_name)
    _qtile.current_screen.set_group(_qtile.groups_map[new_group_name])

  return goto_group_with_current_window


def make_swap_group_content(new_group_name: str):

  @lazy.function
  def swap_group_content(_qtile: Qtile):
    current_group = _qtile.current_group
    new_group = _qtile.groups_map[new_group_name]

    current_group_name: str = current_group.name

    if new_group_name == current_group_name:
      return

    old_layout_name = current_group.layout.name
    old_windows = list(current_group.windows)

    current_group.layout = new_group.layout.name
    for window in new_group.windows:
      window.togroup(current_group_name)

    new_group.layout = old_layout_name
    for window in old_windows:
      window.togroup(new_group_name)

    _qtile.current_screen.set_group(new_group)

  return swap_group_content


visible_group_names = [
  "1",
  "2",
  "3",
  "4",
  "5",
  "6",
  "7",
  "8",
  "9",
  "0",
]
visible_group_labels = [
  "1",
  "2",
  "3",
  "4",
  "5",
  "6",
  "7",
  "8",
  "9",
  "0",
]

group_names = visible_group_names
group_labels = visible_group_labels

groups = [
  Group(
    name=group_names[i],
    label=group_labels[i],
    layout="monadtall",
  ) for i in range(len(group_names))
]

floating_layout: Floating = Floating(
  float_rules=[
    *Floating.default_float_rules,
  ],
  fullscreen_border_width=0,
  border_width=1,
  border_focus=colors["primary"],
  border_normal=colors["accent"],
)

layout_theme = {
  "margin": 8,
  "border_width": 2,
  "single_border_width": 2,
  "border_focus": colors["primary"],
  "border_normal": colors["accent"],
}

layouts = [MonadTall(**layout_theme)]

screens = [Screen(top=bar.Gap(40))]

mouse = [
  Drag(
    [super_mod],
    "Button1",
    lazy.window.set_position_floating(),
    start=lazy.window.get_position(),
  ),
  Drag(
    [super_mod, shift],
    "Button1",
    lazy.window.set_size_floating(),
    start=lazy.window.get_size(),
  ),
]

keys = [
  Key([super_mod, shift], "f", lazy.window.toggle_fullscreen()),
  Key([super_mod], "f", lazy.window.toggle_floating()),
  Key([super_mod], "k", lazy.layout.up()),
  Key([super_mod], "j", lazy.layout.down()),
  Key([super_mod], "h", lazy.layout.left()),
  Key([super_mod], "l", lazy.layout.right()),
  Key(
    [super_mod, control],
    "l",
    lazy.layout.grow_right(),
    lazy.layout.grow(),
    lazy.layout.increase_ratio(),
    lazy.layout.delete(),
  ),
  Key(
    [super_mod, control],
    "h",
    lazy.layout.grow_left(),
    lazy.layout.shrink(),
    lazy.layout.decrease_ratio(),
    lazy.layout.add(),
  ),
  Key(
    [super_mod, control],
    "k",
    lazy.layout.grow_up(),
    lazy.layout.grow(),
    lazy.layout.decrease_nmaster(),
  ),
  Key(
    [super_mod, control],
    "j",
    lazy.layout.grow_down(),
    lazy.layout.shrink(),
    lazy.layout.increase_nmaster(),
  ),
  Key([super_mod, shift], "k", lazy.layout.shuffle_up()),
  Key([super_mod, shift], "j", lazy.layout.shuffle_down()),
  Key([super_mod, shift], "h", lazy.layout.shuffle_left()),
  Key([super_mod, shift], "l", lazy.layout.shuffle_right()),
  Key([super_mod], escape, kill),
  Key(
    [super_mod],
    "space",
    lazy.widget["keyboardlayout"].next_keyboard(),
  ),
]

for group_name in visible_group_names:
  keys.extend([
    Key([super_mod], group_name, make_goto_group(group_name)),
    Key(
      [super_mod, shift],
      group_name,
      make_goto_group_with_current_window(group_name),
    ),
    Key(
      [super_mod, control, shift],
      group_name,
      make_swap_group_content(group_name),
    ),
  ])


@hook.subscribe.client_new
def set_floating(window: Window):
  if not floating_layout.float_rules:
    return False

  float_rules: List[Match] = floating_layout.float_rules
  return functools.reduce(lambda s, x: s or x.compare(window), float_rules,
                          False)
