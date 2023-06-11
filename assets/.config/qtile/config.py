import functools
import os
import subprocess
import re
from typing import List

from libqtile import bar, hook, qtile
from libqtile.backend.x11.window import Window
from libqtile.config import Screen, Group, Match, Key, Click, Drag
from libqtile.core.manager import Qtile
from libqtile.layout.floating import Floating
from libqtile.layout.xmonad import MonadTall
from libqtile.layout.bsp import Bsp
from libqtile.lazy import lazy

from libqtile.widget.caps_num_lock_indicator import CapsNumLockIndicator
from libqtile.widget.chord import Chord
from libqtile.widget.clock import Clock
from libqtile.widget.cpu import CPU
from libqtile.widget.currentlayout import CurrentLayout, CurrentLayoutIcon
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

# IDs

nvidia_bus_id = os.environ.get("QTILE_NVIDIA_BUS_ID", None)
net_interface_id = os.environ.get("QTILE_NET_INTERFACE", None)
cpu_sensor_tag = os.environ.get("QTILE_CPU_SENSOR_TAG", None)
display_brightness_device = os.environ.get(
    "QTILE_DISPLAY_BRIGHTNESS_DEVICE", None
)
keyboard_brightness_device = os.environ.get(
    "QTILE_KEYBOARD_BRIGHTNESS_DEVICE", None
)


# Locations

home_dir = os.path.expanduser("~")
qtile_config_dir = os.path.join(home_dir, ".config", "qtile")
qtile_config_loc = os.path.join(qtile_config_dir, "config.py")

rofi_config_dir = os.path.join(home_dir, ".config", "rofi")
rofi_launcher_loc = os.path.join(rofi_config_dir, "launcher.rasi")

user_dir = os.path.join(home_dir, "user")
pictures_dir = os.path.join(user_dir, "pictures")
screenshot_dir = os.path.join(pictures_dir, "screenshots")
keymap_dir = os.path.join(pictures_dir, "keymap")

scripts_dir = os.path.join(qtile_config_dir, "scripts")
startup_once_loc = os.path.join(scripts_dir, "startup_once.sh")

assets_dir = os.path.join(home_dir, ".local", "share")

wallpaper_dir = os.path.join(assets_dir, "wallpapers")
wallpaper_loc = os.path.join(wallpaper_dir, "magical-forest.jpg")
lock_wallpaper_loc = os.path.join(wallpaper_dir, "cat-roof-city-neon.jpg")


# Special keys

super_mod = "mod4"
control = "control"
shift = "shift"
enter = "Return"
escape = "Escape"
tab = "Tab"
print_screen = "Print"


# Misc

main = None

follow_mouse_focus = False
bring_front_click = False
cursor_warp = False

auto_fullscreen = True

focus_on_window_activation = "focus"

# doesn't mean anything
wmname = "LG3D"

termianl_prefix = "kitty -e fish"


def terminal_wrap(x):
    return "kitty -e fish -c '" + x + "'"


# Colors

# Material Palenight
# https://github.com/samsebastien/windows-terminal-palenight
colors = {
    "transparent": "#00" + "#000000"[1:],
    "background": "#29" + "#191349"[1:],
    "foreground": "#bf" + "#c7d5ff"[1:],
    "black": "#132339",
    "white": "#ffddff",
    "blue": "#82aaff",
    "cyan": "#89ddff",
    "green": "#c3e88d",
    "magenta": "#c792ea",
    "red": "#ff5874",
    "yellow": "#ffeb95",
    "brightBlack": "#3c435e",
    "brightWhite": "#ffffff",
    "brightBlue": "#92baff",
    "brightCyan": "#99fdff",
    "brightGreen": "#c3f88d",
    "brightMagenta": "#d792fa",
    "brightRed": "#ff6884",
    "brightYellow": "#fffba5",
    "dimBlack": "#000200",
    "dimWhite": "#ddccdd",
    "dimBlue": "#72baff",
    "dimCyan": "#79edff",
    "dimGreen": "#b3d87d",
    "dimMagenta": "#b782da",
    "dimRed": "#ff4884",
    "dimYellow": "#ffdb85",
}


def as_transparent(color: str, transparency: str):
    return "#%s%s" % (
        transparency[:2].ljust(2, "0"),
        color.replace("#", "").ljust(6, "0"),
    )


# Defaults

widget_defaults = {
    "padding_x": 5,
    "padding_y": 5,
    "margin_x": 2,
    "margin_y": 2,
    "padding": 5,
    "margin": 5,
    "font": "JetBrainsMono Nerd Font Mono",
    "fontsize": 16,
    "icon_size": 20,
    "background": colors["background"],
    "foreground": colors["foreground"],
    "highlight_method": "text",
    "urgent_alert_method": "block",
    "threshold": 80,
    "urgent_border": colors["red"],
    "foreground_alert": colors["red"],
    "markup": False,
    "rounded": False,
}


# Lazy


@lazy.function
def suspend_os(_: Qtile):
    os.system("systemctl suspend-then-hibernate")


@lazy.function
def hibernate_os(_: Qtile):
    os.system("systemctl hibernate")


@lazy.function
def restart_os(_: Qtile):
    os.system("systemctl reboot")


@lazy.function
def shutdown_os(_: Qtile):
    os.system("systemctl poweroff")


@lazy.function
def lock_user(_: Qtile):
    os.system("betterlockscreen --lock")


@lazy.function
def logoff_user(_qtile: Qtile):
    _qtile.stop()


@lazy.function
def restart_qtile(_qtile: Qtile):
    _qtile.cmd_restart()


@lazy.function
def restart_spotifyd(_: Qtile):
    os.system("systemctl restart --user spotifyd.service")


@lazy.function
def start_spt(_: Qtile):
    terminal_wrap("spt")


@lazy.function
def kill_window(_qtile: Qtile):
    if not _qtile.current_window:
        return

    if _qtile.current_window.name in ["Lutris"]:
        _qtile.current_window.cmd_togroup("0")
        return

    _qtile.current_window.cmd_kill()


@lazy.function
def increase_display_brightness(_: Qtile):
    os.system(f"brightnessctl --device='{display_brightness_device}' set +2%")


@lazy.function
def decrease_display_brightness(_: Qtile):
    os.system(f"brightnessctl --device='{display_brightness_device}' set 2%-")


@lazy.function
def increase_keyboard_brightness(_: Qtile):
    os.system(f"brightnessctl --device='{keyboard_brightness_device}' set +2%")


@lazy.function
def decrease_keyboard_brightness(_: Qtile):
    os.system(f"brightnessctl --device='{keyboard_brightness_device}' set 2%-")


# Lazy factories


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


# Callbacks


def show_net_config():
    qtile.cmd_spawn("nm-connection-editor")


def show_nvidia_temp():
    qtile.cmd_spawn("corectrl")


def show_cpu_temp():
    qtile.cmd_spawn("corectrl")


def show_gpu_config():
    qtile.cmd_spawn("nvidia-settings")


def show_cpu_config():
    qtile.cmd_spawn("corectrl")


def show_process_list():
    qtile.cmd_spawn("lxtask")


def show_input_config():
    qtile.cmd_spawn("lxinput")


def show_keyboard_config():
    qtile.cmd_spawn("fcitx5-configtool")


# Groups

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
    )
    for i in range(len(group_names))
]


# Layouts

floating_layout: Floating = Floating(
    float_rules=[
        *Floating.default_float_rules,
        Match(wm_class="confirmreset"),
        Match(wm_class="pcmanfm"),
        Match(title=re.compile(".*variable.*"), wm_class="DBeaver"),
        Match(wm_class="makebranch"),
        Match(wm_class="maketag"),
        Match(wm_class="feh"),
        Match(wm_class="ssh-askpass"),
        Match(wm_class="pinentry-gtk-2"),
        Match(wm_class="tk"),
        Match(title="branchdialog"),
        Match(title="galculator"),
        Match(title="Open File"),
    ],
    fullscreen_border_width=0,
    border_width=1,
    border_focus=colors["dimCyan"],
    border_normal=colors["dimMagenta"],
)

layout_theme = {
    "margin": 4,
    "border_width": 2,
    "single_border_width": 2,
    "border_focus": colors["dimCyan"],
    "border_normal": colors["dimMagenta"],
}

layouts = [
    MonadTall(**layout_theme),
    Bsp(**layout_theme),
]


# Screens

screens = [
    Screen(
        top=bar.Bar(
            widgets=[
                CurrentLayoutIcon(
                    scale=0.7,
                    background=colors["cyan"],
                ),
                CurrentLayout(
                    fmt=" {:<10}",
                    foreground=colors["cyan"],
                ),
                GroupBox(
                    visible_groups=visible_group_names,
                    this_current_screen_border=colors["yellow"],
                    this_screen_border=colors["yellow"],
                    other_current_screen_border=colors["yellow"],
                    other_screen_border=colors["yellow"],
                    active=colors["green"],
                    inactive=colors["magenta"],
                    disable_drag=True,
                ),
                TextBox(
                    text="|",
                    foreground=colors["blue"],
                ),
                TaskList(
                    padding_x=5,
                    padding_y=0,
                    margin_x=5,
                    margin_y=0,
                    title_width_method="uniform",
                    max_title_width=200,
                    foreground=colors["magenta"],
                    border=colors["cyan"],
                    txt_floating="🗗",
                    txt_minimized=">_",
                ),
                Systray(),
            ],
            size=25,
            background=colors["transparent"],
        ),
        bottom=bar.Bar(
            widgets=[
                Clock(
                    format="%Y %m (%b) %d (%a) %H:%M:%S",
                    foreground=colors["magenta"],
                ),
                TextBox(
                    text="|",
                    foreground=colors["blue"],
                ),
                KeyboardLayout(
                    foreground=colors["cyan"],
                    configured_keyboards=["us", "hr"],
                    mouse_callbacks={"Button1": show_keyboard_config},
                ),
                TextBox(
                    text="|",
                    foreground=colors["blue"],
                ),
                CapsNumLockIndicator(
                    foreground=colors["green"],
                    mouse_callbacks={"Button1": show_input_config},
                ),
                Chord(foreground=colors["yellow"]),
                Spacer(length=bar.STRETCH),
                # TODO: configure laptop things
                *(
                    [
                        Battery(
                            foreground=colors["green"],
                        ),
                        Backlight(
                            foreground=colors["green"],
                            backlight_name=display_brightness_device,
                        ),
                        TextBox(
                            text="|",
                            foreground=colors["blue"],
                        ),
                    ]
                    if display_brightness_device is not None
                    else []
                ),
                *(
                    [
                        Net(
                            interface=[net_interface_id],
                            format="{down:>8}↓{up:>8}↑",
                            foreground=colors["cyan"],
                            mouse_callbacks={
                                "Button1": show_net_config,
                            },
                        ),
                        TextBox(
                            text="|",
                            foreground=colors["blue"],
                        ),
                    ]
                    if net_interface_id is not None
                    else []
                ),
                TextBox(text="Temp", foreground=colors["foreground"]),
                *(
                    [
                        NvidiaSensors(
                            gpu_bus_id=nvidia_bus_id,
                            format="[GPU: {temp}°C]",
                            foreground=colors["yellow"],
                            mouse_callbacks={
                                "Button1": show_nvidia_temp,
                            },
                        ),
                    ]
                    if nvidia_bus_id is not None
                    else []
                ),
                ThermalSensor(
                    fmt="[CPU: {}]",
                    foreground=colors["yellow"],
                    mouse_callbacks={
                        "Button1": show_cpu_temp,
                    },
                    tag_sensor=cpu_sensor_tag,
                ),
                TextBox(
                    text="|",
                    foreground=colors["blue"],
                ),
                TextBox(text="Perf", foreground=colors["foreground"]),
                *(
                    [
                        NvidiaSensors(
                            gpu_bus_id=nvidia_bus_id,
                            format="[GPU: {perf}]",
                            foreground=colors["green"],
                            mouse_callbacks={
                                "Button1": show_gpu_config,
                            },
                        ),
                    ]
                    if nvidia_bus_id is not None
                    else []
                ),
                CPU(
                    format="[CPU:{freq_current: 1.1f}GHz "
                    + "{load_percent: 2.1f}%]",
                    foreground=colors["red"],
                    mouse_callbacks={
                        "Button1": show_cpu_config,
                    },
                ),
                TextBox(
                    text="|",
                    foreground=colors["blue"],
                ),
                Memory(
                    format="Mem: {MemPercent: 2.0f}% "
                    + "Swap: {SwapPercent: 2.0f}%",
                    measure_mem="G",
                    mouse_callbacks={
                        "Button1": show_process_list,
                    },
                    foreground=colors["magenta"],
                ),
            ],
            size=25,
            background=colors["transparent"],
        ),
        wallpaper=wallpaper_loc,
        wallpaper_mode="stretch",
    ),
]


# Mouse

mouse = [
    Drag(
        [super_mod],
        "Button1",
        lazy.window.set_position_floating(),
        start=lazy.window.get_position(),
    ),
    Drag(
        [super_mod, control],
        "Button1",
        lazy.window.set_size_floating(),
        start=lazy.window.get_size(),
    ),
    Click([super_mod], "Button3", lazy.window.bring_to_front()),
    Click([super_mod, control], "Button3", lazy.window.toggle_floating()),
    Click([super_mod, shift], "Button3", lazy.window.toggle_fullscreen()),
]

# Keymap

keys = [
    # Windows
    # layout
    Key([super_mod, shift], "f", lazy.window.toggle_fullscreen()),
    Key([super_mod, control], "f", lazy.window.toggle_floating()),
    Key([super_mod], "n", lazy.layout.normalize()),
    Key([super_mod, control], "space", lazy.next_layout()),
    # focus
    Key([super_mod], "k", lazy.layout.up()),
    Key([super_mod], "j", lazy.layout.down()),
    Key([super_mod], "h", lazy.layout.left()),
    Key([super_mod], "l", lazy.layout.right()),
    # resize
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
    # move
    Key([super_mod, shift], "k", lazy.layout.shuffle_up()),
    Key([super_mod, shift], "j", lazy.layout.shuffle_down()),
    Key([super_mod, shift], "h", lazy.layout.shuffle_left()),
    Key([super_mod, shift], "l", lazy.layout.shuffle_right()),
    Key([super_mod], tab, lazy.screen.next_group()),
    Key([super_mod, shift], tab, lazy.screen.prev_group()),
    # flip for monadtall
    Key([super_mod, control, shift], "f", lazy.layout.flip()),
    # lifecycle
    Key([super_mod], escape, kill_window, desc="Kill"),
    Key([super_mod, control], escape, lazy.spawn("lxsession-logout"), desc="Sleep"),
    Key([super_mod, shift], "c", restart_qtile, desc="Restart Qtile"),
    # keyboard
    Key(
        [super_mod],
        "space",
        lazy.widget["keyboardlayout"].next_keyboard(),
        desc="Layout",
    ),
    # volume
    Key(
        [],
        "XF86AudioPlay",
        lazy.spawn("playerctl play-pause"),
    ),
    Key(
        [],
        "XF86AudioPause",
        lazy.spawn("playerctl play-pause"),
    ),
    Key(
        [],
        "XF86AudioMute",
        lazy.spawn("pactl set-sink-mute '@DEFAULT_SINK@' 'toggle'"),
    ),
    Key(
        [],
        "XF86AudioLowerVolume",
        lazy.spawn("pactl set-sink-volume '@DEFAULT_SINK@' '-2%'"),
    ),
    Key(
        [],
        "XF86AudioRaiseVolume",
        lazy.spawn("pactl set-sink-volume '@DEFAULT_SINK@' '+2%'"),
    ),
    # brightness
    Key(
        [],
        "XF86MonBrightnessUp",
        increase_display_brightness,
        desc="Display brightness +",
    ),
    Key(
        [],
        "XF86MonBrightnessDown",
        decrease_display_brightness,
        desc="Display brightness -",
    ),
    Key(
        [shift],
        "XF86MonBrightnessUp",
        increase_keyboard_brightness,
        desc="Keyboard brightness +",
    ),
    Key(
        [shift],
        "XF86MonBrightnessDown",
        decrease_keyboard_brightness,
        desc="Keyboard brightness -",
    ),
    # update
    Key(
        [super_mod, shift],
        "u",
        lazy.spawn(terminal_wrap("paru -Syu")),
        lazy.spawn(terminal_wrap("nvim -c PackerSync")),
        desc="Keymap",
    ),
    # config
    Key(
        [super_mod, control],
        "c",
        lazy.spawn(
            f"gen-keybinding-img -o '{keymap_dir}' -c '{qtile_config_loc}'"
        ),
        lazy.spawn(f"feh '{keymap_dir}'"),
        desc="Keymap",
    ),
    Key(
        [super_mod],
        "c",
        lazy.spawn(terminal_wrap(f"cd '{qtile_config_dir}'; nvim config.py")),
        desc="Config",
    ),
    # apps
    Key(
        [super_mod],
        enter,
        lazy.spawn(
            f"rofi -show drun -modi run,drun,window -config {rofi_launcher_loc}"
        ),
        desc="Launch",
    ),
    Key(
        [super_mod, control],
        enter,
        lazy.spawn("lxtask"),
        desc="Tasks",
    ),
    # screenshot
    Key(
        [super_mod],
        print_screen,
        lazy.spawn("flameshot full -p " + screenshot_dir),
        desc="Screenshot",
    ),
    Key(
        [super_mod, control],
        print_screen,
        lazy.spawn("flameshot gui -p " + screenshot_dir),
        desc="Screenshot",
    ),
    # shortcuts
    Key(
        [super_mod, control],
        "v",
        lazy.spawn("pavucontrol"),
        desc="Volume",
    ),
    Key(
        [super_mod],
        "f",
        lazy.spawn("pcmanfm"),
        desc="File manager",
    ),
    Key(
        [super_mod],
        "v",
        # FIX: this opens builtin for some reason
        lazy.spawn(terminal_wrap("nvim -c 'Telescope project'")),
        desc="Neovim",
    ),
    Key(
        [super_mod],
        "p",
        lazy.spawn("keepmenu -a '{USERNAME}{TAB}{PASSWORD}'"),
        desc="Fill credentials",
    ),
    Key(
        [super_mod, control],
        "p",
        lazy.spawn("keepmenu -a '{PASSWORD}'"),
        desc="Fill password",
    ),
    Key([super_mod, shift], "p", lazy.spawn("keepassxc"), desc="Passwords"),
    Key([super_mod], "t", lazy.spawn("kitty"), desc="Terminal"),
    Key([super_mod], "e", lazy.spawn("emote"), desc="Emotes"),
    Key([super_mod], "w", lazy.spawn("brave"), desc="Browse"),
    Key(
        [super_mod, control],
        "w",
        lazy.spawn("brave --incognito"),
        desc="Incognito",
    ),
    Key([super_mod, shift], "w", lazy.spawn("brave --tor"), desc="Tor"),
    Key([super_mod], "m", lazy.spawn("ferdi"), desc="Communication"),
    Key([super_mod], "s", lazy.spawn(terminal_wrap("spt")), desc="Spotify"),
    Key(
        [super_mod, control],
        "s",
        lazy.spawn("systemctl restart --user spotifyd.service"),
        lazy.spawn("keepmenu -a '{PASSWORD}{ENTER}'"),
        desc="Spotifyd",
    ),
]

for group_name in visible_group_names:
    keys.extend(
        [
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
        ]
    )


# Hooks


@hook.subscribe.startup_once
def start_once():
    subprocess.call([startup_once_loc])


@hook.subscribe.client_new
def set_floating(window: Window):
    if not floating_layout.float_rules:
        return False

    float_rules: List[Match] = floating_layout.float_rules
    return functools.reduce(
        lambda s, x: s or x.compare(window), float_rules, False
    )
