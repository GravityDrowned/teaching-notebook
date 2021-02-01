def test_python_version():
    import sys
    assert sys.version_info.major == 3
    assert sys.version_info.minor == 8

def test_tensorflow():
    import tensorflow
