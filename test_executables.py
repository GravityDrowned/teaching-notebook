import shutil

executables = [
    "flex",
    "yacc",
]


def is_available(exe: str) -> bool:
    return shutil.which(exe) is not None


def test_executables() -> None:
    missing = [exe
               for exe in executables
               if not is_available(exe)]
    assert not missing, f"Missing executables: {', '.join(missing)}"
