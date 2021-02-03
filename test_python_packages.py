def test_python_version() -> None:
    import sys
    assert sys.version_info.major == 3
    assert sys.version_info.minor == 8


def test_tensorflow() -> None:
    import tensorflow  # type: ignore
    tensorflow


def test_nbgrader() -> None:
    import nbgrader    # type: ignore
    assert nbgrader.version_info == (0, 7, 0, 'dev')
