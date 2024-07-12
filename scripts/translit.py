import sys
import subprocess

dict = {
    "а": "a",
    "б": "b",
    "в": "v",
    "г": "g",
    "д": "d",
    "е": "e",
    "ё": "e",
    "ж": "zh",
    "з": "z",
    "и": "i",
    "й": "j",
    "к": "k",
    "л": "l",
    "м": "m",
    "н": "n",
    "о": "o",
    "п": "p",
    "р": "r",
    "с": "s",
    "т": "t",
    "у": "u",
    "ф": "f",
    "х": "kh",
    "ц": "ts",
    "ч": "ch",
    "ш": "sh",
    "щ": "sch",
    "ъ": "j",
    "ы": "y",
    "ь": "",
    "э": "e",
    "ю": "ju",
    "я": "ya",
    }
dict_upper = {k.upper(): v.capitalize() for k, v in dict.items()}
dict.update(dict_upper)
dict.update({" ": "_"})

for filename in sys.argv[1:]:
    translit = []
    for letter in filename:
        if letter in dict:
            translit.append(dict[letter])
        else:
            translit.append(letter)
    translit = "".join(translit)

    if translit != filename and translit != "Telegram_Desktop":
        subprocess.Popen(['mv', '-iv', f'{filename}', f'{translit}'])
